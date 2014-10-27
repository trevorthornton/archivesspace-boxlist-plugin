class AjaxUtilityController < ApplicationController

  set_access_control  "view_repository" => [:get_json],
                      "update_archival_record" => [:post]

  def get_json
    @uri = params[:uri]
    @query_params = {}
    params.each do |k,v|
      if ![:controller, :action, :uri].include?(k)
        if v.kind_of? Array
          # Fix arrays (esp 'resolve') to work correctly
          @query_params["#{k.to_s}[]"] = v
        else
          @query_params[k.to_s] = v
        end
      end
    end
    @response = JSONModel::HTTP::get_json("/#{@uri}",@query_params)
    render json: @response, layout: false
  end

  def post_json
    @uri = params[:uri]
    @json = params[:json] || '{}'
    JSONModel::HTTP::post_json(@uri, @json)
    render json: @response, layout: false
  end

end