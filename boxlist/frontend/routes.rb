ArchivesSpace::Application.routes.draw do
  # get '/api/*uri' => 'ajax_utility#get_json'
  # post '/api/*uri' => 'ajax_utility#post_json'

  get 'boxlist/:resource_id' => 'boxlist#show'
  get 'boxlist_data/:resource_id' => 'boxlist#data'
end
