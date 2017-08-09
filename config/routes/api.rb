scope module: :api, as: 'api' do
  resources 'switches', only: [] do
    collection do
      get :scrape
    end
  end
end
