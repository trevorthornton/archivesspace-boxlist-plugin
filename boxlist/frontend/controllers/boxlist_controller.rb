class BoxlistController < ApplicationController

  require 'active_support/inflector'

  set_access_control  "view_repository" => [:show, :data]

  def show
    if params[:resource_id]
      @resource_id = params[:resource_id]
      @resource = JSONModel(:resource).find(@resource_id)
      render
    end
  end


  def data
    if params[:resource_id]
      @resource = JSONModel(:resource).find(params[:resource_id])
      @resource_uri = @resource.uri
      @tree = JSONModel::HTTP::get_json("/#{@resource_uri}/tree")
      @list = {}
      resource_children = @tree['children']
      process_children(resource_children)
      consolidate_list(@list)
      if @list.empty?
        @rows = []
      else
        @rows = rows_from_list
        @rows.sort_by! { |x| x[:container_sort] }
      end
      render json: JSON.generate(@rows)
    end
  end



  private


  def process_instance(instance)
    cont = instance['container']
    if cont

      locations = []

      if cont['container_locations']
        cont['container_locations'].each do |loc|
          locations << loc['ref']
        end
      end

      hash_keys = []
      3.times do |n|
        index = (n + 1).to_s
        if cont["type_#{index}"]
          type = cont["type_#{index}"]
          indicator = cont["indicator_#{index}"]
          hash_keys << [ type, indicator ]
        end
      end

      locations.each do |l|
        @list[l] ||= {}
        list_root = @list[l]
        hash_keys.each do |k|
          if !k.nil?
            list_root[k] ||= {}
            list_root = list_root[k]
          end
        end
      end

    end
  end


  def process_children(children)
    children.each do |c|
      puts c['record_uri']
      # c_data = JSONModel::HTTP::get_json(c['record_uri'], resolve: ['instances'])
      c_data = JSONModel::HTTP::get_json(c['record_uri'])
      c_data['instances'].each do |i|
        process_instance(i)
      end

      if ['has_children']
        process_children(c['children'])
      end
    end
  end


  def consolidate_list(list)
    values = nil
    list.each do |k,v|
      if (!v || v.empty?)
        (values ||= []) << k
        list.delete(k)
      else
        consolidate_list(list[k])
      end
    end
    if values
      values.uniq!
      values.each do |v|
        if v[1]
          list[v[0]] ||= { 'values' => [] }
          list[v[0]]['values'] << v[1]
        end
      end
    end
  end


  def contents_statement(key, values)
    numeric_values = true

    values.each do |value|
      if !value.match(/^[\d\-\,\s]+$/)
        numeric_values = false
        break
      end
    end

    if numeric_values
      number_part = ''
      clean_values = []
      values.map! { |s| s.strip }
      values.each do |value|
        if value.match(/^\d+$/)
          clean_values << value.to_i
        elsif value.match(/^\d+\-\d+$/)
          range = value.split('-')
          (range[0].to_i..range[1].to_i).each { |n| clean_values << n }
        elsif value.match(/^[\d\,]+$/)
          value_list = value.split(',').map { |s| s.strip.to_i }
          clean_values << value_list
        end
      end

      # values.map! { |value| value.to_i }
      values = clean_values.uniq
      values.sort!
      previous = 0

      values.each do |value|
        if value == values.first
          number_part << value.to_s
        elsif value == (previous + 1)
          if number_part[number_part.length - 1] != '-'
            number_part << '-'
          end
          if value == values.last
            number_part << value.to_s
          end
        else
          if number_part[number_part.length - 1] == '-'
            number_part << previous.to_s
          end
          number_part << ", #{value.to_s}"
        end
        previous = value
      end
      statement = "#{key.pluralize(values.length)} #{number_part}"
    else
      statement = ''
      values.each do |value|
        statement << "#{key} #{value}"
        statement += (value != values.last) ? ', ' : ''
      end
    end

    statement
  end



  def rows_from_list
    rows = []

    @list.each do |k,v|

      location_ref = k
      location_data = JSONModel::HTTP::get_json(location_ref)
      location_title = location_data['title']

      if v['values']
        v['values'].each do |value|
          rows << { location: location_title, container: value }
        end
        if v.length > 1
          # ??????
        end
      else

        # container level 1
        v.each do |k1,v1|
          if v1['values']
            v1['values'].each do |value|
              rows << { location: location_title, container_type: k1, container_value: value }
            end
            if v1.length > 1
              # ??????
            end
          else

            # container level 2
            v1.each do |k2,v2|

              if v2['values']
                contents = contents_statement(k2, v2['values'])
                rows << { location: location_title, container_type: k1[0], container_value: k1[1], contents: contents }
                if v2.length > 1
                  # ??????
                end
              else

                # container level 2
                v2.each do |k3,v3|
                  if v3['values']
                    contents = contents_statement(k3, v3['values'])
                    rows << { location: location_title, container_type: k1[0], container_value: k1[1], subcontainer_type: k2[0], subcontainer_value: k2[1], contents: contents }
                    if v3.length > 1
                      # ??????
                    end
                  else
                    # ???
                  end
                end

              end
            end
          end
        end
      end
    end

    # Generate container string and sort value
    values = rows.map { |row| row[:container_value] }.reject { |row| row.nil? }
    max_value_length = values.max_by { |v| v.length }.length

    rows.each do |row|
      container_sort = ''
      if row[:container_type]
        row[:container] = row[:container_type]
        row[:container] += row[:container_value] ? " #{row[:container_value]}" : ''

        container_sort << row[:container_type]
        sort_value = row[:container_value] || ''
        sort_value.strip.split(/[^A-Za-z0-9]/).each do |v|
          value_length_diff = max_value_length - v.length
          value_length_diff.times { |n| container_sort << '0' }
          container_sort << v
        end
        row[:container_sort] = container_sort
      else
        row[:container_sort] = ''
      end

      if row[:subcontainer_type]
        row[:subcontainer] = row[:subcontainer_type]
        row[:subcontainer] += row[:subcontainer_value] ? " #{row[:subcontainer_value]}" : ''
      end

    end
    rows
  end



end
