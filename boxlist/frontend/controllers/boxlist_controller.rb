class BoxlistController < ApplicationController

  require 'active_support/inflector'

  set_access_control  "view_repository" => [:show, :data]

  def show
    if params[:resource_id]
      @resource_id = params[:resource_id]
      @resource = JSONModel(:resource).find(@resource_id)
      # @resource_uri = @resource.uri
      # @tree = JSONModel::HTTP::get_json("/#{@resource_uri}/tree")
      # @list = {}
      # # tree = JSON.parse(@tree_response.body)
      # resource_children = @tree['children']
      # process_children(resource_children)
      # consolidate_list(@list)
      # @rows = rows_from_list
      render
    end
  end


  def data
    if params[:resource_id]
      @resource = JSONModel(:resource).find(params[:resource_id])
      @resource_uri = @resource.uri
      @tree = JSONModel::HTTP::get_json("/#{@resource_uri}/tree")
      @list = {}
      # tree = JSON.parse(@tree_response.body)
      resource_children = @tree['children']
      process_children(resource_children)
      consolidate_list(@list)
      @rows = rows_from_list
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
          if n == 0
            hash_keys << "#{type} #{indicator}"
          else
            hash_keys << type
            hash_keys << indicator
          end
        end
      end

      locations.each do |l|
        @list[l] ||= {}
        list_root = @list[l]
        hash_keys.each do |k|
          list_root[k] ||= {}
          list_root = list_root[k]
        end
      end

    end
  end


  def process_children(children)
    children.each do |c|
      puts c['record_uri']
      # c_data = JSONModel::HTTP::get_json(c['record_uri'], resolve: ['instances'])
      c_data = JSONModel::HTTP::get_json(c['record_uri'])

      puts "******"
      puts c_data.inspect
      puts "******"

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
      list['values'] = values.uniq
    end
    sort_hash_by_key(list)
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
      location = location_data['title']

      if v['values']
        v['values'].each do |value|
          rows << { location: location, container: value }
        end
        if v.length > 1
          # ??????
        end
      else

        # container level 1
        v.each do |k1,v1|
          if v1['values']
            v1['values'].each do |value|
              rows << { location: location, container: value }
            end
            if v1.length > 1
              # ??????
            end
          else

            # container level 2
            v1.each do |k2,v2|
              if v2['values']
                contents = contents_statement(k2, v2['values'])
                rows << { location: location, container: k1, contents: contents }
                if v2.length > 1
                  # ??????
                end
              else

                # container level 2
                v2.each do |k3,v3|
                  if v3['values']
                    contents = contents_statement(k3, v3['values'])
                    rows << { location: location, container: k2, contents: contents }
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
    rows
  end


  def sort_hash_by_key(hash)
    a = hash.sort_by { |k,v| k }
    new_hash = {}
    a.each { |aa| new_hash[aa[0]] = aa[1] }
    hash = new_hash
    hash.each do |k,v|
      if v.kind_of? Hash
        sort_hash_by_key(v)
      end
    end
    hash
  end

end
