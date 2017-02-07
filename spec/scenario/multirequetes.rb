require 'airborne'
require 'base64'
Airborne.configure do |config|
  config.base_url = 'http://localhost:3000'
  # config.base_url = 'http://api.playarshop.com/'
end


describe 'Company' do
  it 'Sign Up' do
    post '/shops/sign_up',
      {
          "email": "scenario1@example.com",
          "password": "password"
      }
      token = json_body[:auth_token]
      Airborne.configure do |config|
        config.headers = {
            'Authorization': 'AUTH-BASIC ' + token,
            'Content-Type': 'application/json'
        }
      end
    expect_status(200)
  end
  it 'Connexion' do
    post '/shops/sign_in',
      {
          "email": "scenario1@example.com",
          "password": "password"
      }
      token = json_body[:auth_token]
      puts token
      Airborne.configure do |config|
        config.headers = {
            'Authorization': 'AUTH-BASIC ' + token,
            'Content-Type': 'application/json'
        }
      end
    expect_status(200)
  end

  it 'POST Company' do
    logo = Base64.encode64(File.read("./public/logo_stmich.jpg"))
    target = Base64.encode64(File.read("./public/target_stmich.jpg"))
    # target = Base64.encode64(File.open("./public/uploads/6b48abcc-a3e5-4b41-b830-8d49ba6353fe.jpg") {|img| img.read})
    puts "data:image/png;base64," + target
    post '/companies',
    {
      "company": {
          "name": "playarshop",
          "logo": "data:image/png;base64," + logo
        }
    }
    expect_status(201)
  end



  it 'POST Target' do
    # target1 = Base64.encode64(File.read("./public/logo.png"))
    target2 = Base64.encode64(File.read("./public/target2.jpg"))
    # target3 = Base64.encode64(File.read("./public/target3.jpg"))
    # target4 = Base64.encode64(File.read("./public/target4.jpg"))
    # target = Base64.encode64(File.open("./public/uploads/6b48abcc-a3e5-4b41-b830-8d49ba6353fe.jpg") {|img| img.read})
    # puts "data:image/png;base64," + target
    post '/targets',
    {
        "target": [{
            "place": "rennes",
            "city": "RENNES",
            "image": "data:image/png;base64," + target2
              }]
      }
    # @game_ref = json_body[:game_ref]
    # print @game_ref
    expect_status(201)
  end

  it 'POST target' do
    logo = Base64.encode64(File.read("./public/logo_stmich.jpg"))
    target = Base64.encode64(File.read("./public/target_stmich.jpg"))
    # target = Base64.encode64(File.open("./public/uploads/6b48abcc-a3e5-4b41-b830-8d49ba6353fe.jpg") {|img| img.read})
    puts "data:image/png;base64," + target
    post '/games',
    {
      "game_ref": "@game_ref",
      "game": [{
          "ref": 4,
          "name": "Chasse au tresor",
          "description": "Trouves toutes les cibles",
          # "image": "data:image/png;base64," + logo,
          # "logo": "data:image/png;base64," + target,
          "color1": "#8F3985",
          "color2": "#61E786",
          "perso1": "Blabla",
          "perso2": "Bloblo",
          "custom": "custom"
        }]
    }
    expect_status(201)
  end

  # it 'editor' do
  #   get '/games/1/editor'
  #   expect_status(200)
  # end
  #
  it 'POST DISCOUNTS' do
    post '/discounts',
      {
        "game_ref": "@game_ref",
        "discount": [{
          "success": "Trouves la licorne",
          "fail": "Trouves la licorne quand même"
        }]
      }
    expect_status(201)
  end

end
