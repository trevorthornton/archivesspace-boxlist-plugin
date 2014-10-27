ArchivesSpace::Application.routes.draw do
  # get '/api/*uri' => 'ajax_utility#get_json'
  # post '/api/*uri' => 'ajax_utility#post_json'

  get 'boxlist/*resource_uri' => 'boxlist#show'
end
