class CompaniesController < ApplicationController
  before_action :set_company, only: [:show, :edit, :update, :destroy]
  # after_create :upload_Vuforia
  # GET /companies
  # GET /companies.json
  def index
    @user = User.find(current_user.id)
    @companies = Company.find_by(user_id: @user.id)
    print @companies.inspect
    if !@companies.nil?
      return render json: @companies
    else
      return render json:{  "error": "No company" }, status: 200
    end
  end

  api :GET, '/companies/all', "Récupérer les lieux de jeu"
  description <<-EOS
    === Requête
      {
          {
            "spots": [
                {
                    "name": "Epitech",
                    "location": "Paris",
                    "description": "Ecole pour l'informatique",
                    "adress": "65, rue Parmentier, 75004",
                    "phone": "+33 7 56 78 65 34"
                },
                {
                    "name": "Wargame",
                    "location": "Rennes",
                    "description": "Bornes de jeux",
                    "adress": "22, rue de la mairie, 34500",
                    "phone": "+33 3 90 98 56 54"
                }
            ]
        }
      }
    === Réponse
      Code OK => 201
  EOS
  error :code => 401, :desc => "Non autorisé"
  def all
      @companies = Company.all
      print @companies.inspect
  end

  def payment
    @amount = 500

    customer = Stripe::Customer.create(
      :email => "vincent.galoger@gmail.com",
# /      :email => params[:stripeEmail],
      # :source  => params[:stripeToken]
      :source  => 'pk_test_YFUrNs3byh7cEoZiyM0L3qhO '
    )

    charge = Stripe::Charge.create(
      :customer    => customer.id,
      :amount      => @amount,
      :description => 'Rails Stripe customer',
      :currency    => 'usd'
    )
    # rescue Stripe::CardError => e
    #   flash[:error] = e.message
    #   redirect_to new_charge_path
    # end
  end

  api :POST, '/companies', "Créer une company"
  description <<-EOS
    === Requête
      {
        "company": {
            "name": "playarshop",
            "logo": "data:image/png;base64," + logo
          }
      }
    === Réponse
      Code OK => 201
  EOS
  error :code => 401, :desc => "Non autorisé"
  def create
      @user = User.find(current_user.id)
      @user.company.create(company_params)
      puts @user.inspect
      return render json:{  "Status": "Company created" }, status: 201
  end

    api :GET, '/location', "Récupérer les entrerprises et lieux de jeux"
    description <<-EOS
      === Réponse
        Headers : Location: url du jeu
        Code : 200 si OK
        Body :
              {
                "company": [
                  {
                    "name": "Company 1",
                    "location": null,
                    "lat": "2",
                    "lng": "4",
                    "logo": null,
                    "target": [
                      {
                        "id": 2,
                        "vuforia_name": "",
                        "transaction_id": "",
                        "target_id": null,
                        "image": {
                          "url": null
                        },
                        "path": "",
                        "place": "",
                        "city": "Paris",
                        "discountChance": "",
                        "discountRate": "",
                        "company_id": 1,
                        "game_id": null,
                        "created_at": "2017-01-03T20:17:42.242Z",
                        "updated_at": "2017-01-03T20:17:44.073Z"
                      },
                      {
                        "id": 1,
                        "vuforia_name": "",
                        "transaction_id": "",
                        "target_id": null,
                        "image": {
                          "url": null
                        },
                        "path": "",
                        "place": "Comptoir de Mac Do",
                        "city": "Rennes",
                        "discountChance": "",
                        "discountRate": "",
                        "company_id": 1,
                        "game_id": null,
                        "created_at": "2017-01-03T20:17:31.755Z",
                        "updated_at": "2017-01-03T20:17:44.067Z"
                      }
                    ]
                  }
                ]
              }
    EOS
  def location
    @user = User.find(current_user.id)
    @target = @user.company
    print @target.inspect
    # return render :json => @target.to_json()
  end

  def upload_Vuforia
    access_key = '16e5c472cbad4e592e977029af54b1500b551362'
    secret_key = '932998f43862357f0da1a3e9b0340f5b38c55eb1'
    connection = Vws::Api.new(access_key, secret_key)
    width = 32
    active_flag = true
    application_metadata = nil
    puts @target.image.inspect
    puts vuforia_return = "ok"
    vuforia_return = connection.add_target(target_name, "http://api.playarshop.com" + @target.image.url, width, active_flag, application_metadata)
    # vuforia_return = connection.add_target(target_name, "./public/logo.png", width, active_flag, application_metadata)
    puts vuforia_return.inspect
  end

  api :POST, '/companies', "Créer un entreprise, cible et jeu"
  description <<-EOS
    === Requête
      {
        "company": {
            "name": "playarshop",
            "logo": "base64_image"
          },
          "target": [{
            "place": "rennes",
            "city": "RENNES"
            }, {
              "place": "Germont",
              "image": "base64_image2" }],
            "game": [{
              "name": "otto"
            }, {
              "name": "fdjfds"
              }],
            "discount": {
              "success": "Bravo vous avez gagné 42%",
              "fail": "Raté !"
            }
       }
    === Réponse
      Headers : Location: url du jeu
      Code : 200 si OK
      Body : {}

  EOS
  error :code => 401, :desc => "Non autorisé"
  def create_all
    puts current_user.id
    @user = User.find(current_user.id)
    puts @user.inspect

    @company = @user.company.create(company_params)
    @company.logo = company_params[:logo]
    @company.save!

    target_name = Digest::SHA1.hexdigest([Time.now, rand].join)
    # @target.image = target_params[:image]
    # @target.vuforia_name = target_name
    # # @target.city = io
    # @target.save!
    # #
    access_key = '16e5c472cbad4e592e977029af54b1500b551362'
    secret_key = '932998f43862357f0da1a3e9b0340f5b38c55eb1'
    connection = Vws::Api.new(access_key, secret_key)
    width = 32
    active_flag = true
    application_metadata = nil
    # puts @target.image.inspect
    # puts vuforia_return = "ok"
    # vuforia_return = connection.add_target(target_name, "./public/uploads/file.jpg", width, active_flag, application_metadata)
    # puts vuforia_return.inspect
    # connection_hash = JSON.parse(vuforia_return)
    # @target.transaction_id = connection_hash["transaction_id"]
    # @target.target_id = connection_hash["target_id"]
    # @target.save    targets = params.require(:target)
    targets.each do |t|
      @company.targets.create(t.permit(:place, :image, :city))
      vuforia_return = connection.add_target(target_name, "http://api.playarshop.com" + @company.targets.last.image.url, width, active_flag, application_metadata)
      # vuforia_return = connection.add_target(target_name, "http://localhost:3000" + @company.targets.last.image.url, width, active_flag, application_metadata)

    end

    # params[:game].each_value {|game_attributes| game_attributes.store("company_id", current_user.id)}
    # games = params[:game].collect {|key, game_attributes| Game.new(game_attributes)}
    # @games = []
    games = params.require(:game)
    puts games.inspect
    games.each do |g|
        @company.games.create(g.permit(:ref, :name, :description, :logo, :color1, :color2, :perso1, :perso2, :custom, :discount, :vuforia_name))
        puts g.inspect
        # game.save
        # @games << game
    end
    puts @games.inspect
    # var = Target.new
    # var.uploadVuforia

    # @company.targets.create(target_params)
    # # @company.targets.create(vuforia_name: "test")
    # @target = Target.find_by(id: @company.targets.last.id)
    # target_name = Digest::SHA1.hexdigest([Time.now, rand].join)
    # # io = AvatarStringIO.new(Base64.decode64(target_params[:image]))
    # @target.image = target_params[:image]
    # @target.vuforia_name = target_name
    # # @target.city = io
    # @target.save!
    # #
    # access_key = '16e5c472cbad4e592e977029af54b1500b551362'
    # secret_key = '932998f43862357f0da1a3e9b0340f5b38c55eb1'
    # connection = Vws::Api.new(access_key, secret_key)
    # width = 32
    # active_flag = true
    # application_metadata = nil
    # puts @target.image.inspect
    # puts vuforia_return = "ok"
    # vuforia_return = connection.add_target(target_name, "http://api.playarshop.com" + @target.image.url, width, active_flag, application_metadata)
    # vuforia_return = connection.add_target(target_name, "./public/uploads/file.jpg", width, active_flag, application_metadata)
    # puts vuforia_return.inspect
    # connection_hash = JSON.parse(vuforia_return)
    # @target.transaction_id = connection_hash["transaction_id"]
    # @target.target_id = connection_hash["target_id"]
    # @target.save
    #
    # @game = @company.games.create(game_params)
    # @game.vuforia_name = target_name
    # @game.logo = @target.image.url
    # @game.save!
    #
    @discount = @company.discounts.create(discount_params)
    @discount.game_id = @company.games.last.id
    @discount.save!

    #
    # puts @target.inspect
    # puts @game.inspect
    # puts @discount.inspect
    return render json: {"success": "success"}, status: 302
  end

  api :GET, '/companies', "Récupérer l'entreprise, le logo"
  description <<-EOS
    === Réponse
      {
          "name": "name",
          "logo": "url de l'image",
          "siret": "siret"
      }
  EOS
  error :code => 401, :desc => "Non autorisé"
  param :name, String, :desc => "Nom du jeu", :required => true
  def show
    @company = Company.find_by(id: company_params[:id])
    # file_name = File.read("./public/" + @company.logo.url)
    @base64 = @company.logo.url#Base64.encode64(file_name)
  end

  # GET /companies/new
  def new
    @company = Company.new
  end

  # GET /companies/1/edit
  def edit
  end

  # POST /companies
  # POST /companies.json
  # def create
  #   @company = Company.new(company_params)
  #
  #   respond_to do |format|
  #     if @company.save
  #       format.html { redirect_to @company, notice: 'Company was successfully created.' }
  #       format.json { render :show, status: :created, location: @company }
  #     else
  #       format.html { render :new }
  #       format.json { render json: @company.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end

  # PATCH/PUT /companies/1
  # PATCH/PUT /companies/1.json
  def update
    respond_to do |format|
      if @company.update(company_params)
        format.html { redirect_to @company, notice: 'Company was successfully updated.' }
        format.json { render :show, status: :ok, location: @company }
      else
        format.html { render :edit }
        format.json { render json: @company.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /companies/1
  # DELETE /companies/1.json
  def destroy
    @company.destroy
    respond_to do |format|
      format.html { redirect_to companies_url, notice: 'Company was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def recap
    puts @current_user.inspect
    @shop = Shop.find_by(id: @current_user.user_type_id)
    @company = Company.find_by(id: @shop.company_id)
    puts @company.inspect
    @target = @company.targets.last
    puts @target.inspect
    @game = Game.find_by(id: @company.games.last.id)
    @discount = Discount.find_by(id: @company.discounts.last.id)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_company
      @company = Company.find(params[:id])
    end
    def discount_params
      params.require(:discount).permit(:success, :fail)
    end

    def target_params
      params.require(:target).permit(:place, :image, :city)
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    # def game_params
      # params.require(:game).permit(:ref, :name, :description, :logo, :color1, :color2, :perso1, :perso2, :custom, :discount, :vuforia_name)
    # end
    # Never trust parameters from the scary internet, only allow the white list through.
    def company_params
      params.require(:company).permit(:name, :logo, :siret)
    end
end
