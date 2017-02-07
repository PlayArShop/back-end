class GamesController < ApplicationController
  before_action :set_game, only: [:edit, :update, :destroy]

  # GET /games
  # GET /games.json
  api :GET, '/games ', "Récupérer les jeux personnalisés"
  description <<-EOS
    === Autorisation nécessaire
    === Status
      200
    === Réponse
      {
        "games": [
          {
            "id": 1,
            "game_ref": "",
            "ref": "d",
            "description": "sd",
            "image": null,
            "color1": "",
            "color2": ""
          },
          {
            "id": 2,
            "game_ref": "",
            "ref": "sdd",
            "description": "",
            "image": "/uploads/9fc7bc05-c5b5-4885-8795-4b377f83d3ea.gif",
            "color1": "",
            "color2": ""
          }
        ]
      }
  EOS
  error :code => 401, :desc => "Vuforia name not found"
  def index
    if @current_user.company.last.nil?
      return render json: {  "error": "No company" }, status: 200
    end
    @games = @current_user.company.last.games.all
    if @games.nil?
      return render json: {  "error": "No games" }, status: 200
    end
  end


  api :GET, '/games/:vuforia_name', "Récupérer un jeu"
  api :GET, '/games/:id', "Récupérer un jeu"
  description <<-EOS
    === Autorisation nécessaire
      Aucune autorisation n'est nécessaire pour effectuer cette action. Un token est retourné pour pouvoir ensuite effectuer les actions nécessitant une autorisation.
    === Status
      200
    === Réponse
      {
        "id": 3,
        "ref": 1,
        "name": "Ballons ",
        "description": "Eclates les ballons",
        "logo": "logo en base 64",
        "color1": "rouge",
        "color2": "bleu",
        "perso1": "Jeu de Jacquie",
        "perso2": "et Michèle",
        "custom": "custom",
        "discount": "Vous avez gagné 42% de réduction",
        "vuforia_name": "189d6c2a8a5ad19fc1aa2c89c9d57850c4770470"
      }
  EOS
  error :code => 401, :desc => "Vuforia name not found"
  param :vuforia_name, String, :desc => "Nom de la cible retourné par Vuforia quand détecté", :required => false
  param :name, String, :desc => "Nom du jeu", :required => false
  param :logo, String, :desc => "Logo en base 64", :required => false
  param :color1, String, :desc => "Personnalisation couleur 1", :required => false
  param :color2, String, :desc => "Personnalisation couleur 2", :required => false
  param :perso2, String, :desc => "Personnalisation 1", :required => false
  param :perso1, String, :desc => "Personnalisation 2", :required => false
  param :custom, String, :desc => "Customisation", :required => false
  def show
    # @target = Company.find_by(id: @game.company_id)
    # @target_logo = File.read("./public/" + @target.logo.url)
    # @target_logo = @game.image.url
    # @target_logo = Base64.encode64(file_target)
    #render json: "show.json.jbuilder"
    #print params.inspect
    #t = Target.where(vuforia_name: params.require(:id))
    @targets = Target.where(transaction_id: params.require(:id))
    print @targets.inspect
    if @targets.empty?
       @targets = Target.where(vuforia_name: params.require(:id))
    end
    # i = 0
    # index = 0
    # while (i < targets.size)
    #   print targets[i].inspect + "------------------"
    #   if (params.require(:id) == targets[i].vuforia_name)
    #     i = targets.size
    #   end
    #   i += 1
    #   index += 1
    # end
    @game = Game.where(perso1: @targets[0].transaction_id)
    print @game.inspect
    if @game.nil?
      return render :json => { "error": "no games"}, status: 422
    end
    return render :json => {
      :targets => @targets.as_json(),
      :game => @game.as_json()
    }, status: 200
    @game = game[index - 1]
  end

  # GET /games/new
  def new
    @game = Game.new
  end

  # GET /games/1/edit
  def edit
  end


  error :code => 401, :desc => "Non autorisé"
  def create_all_game
    @user = User.find(current_user.id)
    @company = @user.company.create(company_params)
    @company.logo = company_params[:logo]
    @company.save!
    @company.targets.create(target_params)
    #@company.targets.create(vuforia_name: "test")
    @target = Target.find_by(id: @company.targets.last.id)
    target_name = Digest::SHA1.hexdigest([Time.now, rand].join)
    # io = AvatarStringIO.new(Base64.decode64(target_params[:image]))
    @target.image = target_params[:image]
    @target.vuforia_name = target_name
    # @target.city = io
    @target.save!

    access_key = '16e5c472cbad4e592e977029af54b1500b551362'
    secret_key = '932998f43862357f0da1a3e9b0340f5b38c55eb1'
    connection = Vws::Api.new(access_key, secret_key)
    width = 32
    active_flag = true
    application_metadata = nil
    puts @target.inspect
    vuforia_return = connection.add_target(target_name, "http://api.playarshop.com" + @target.image.url, width, active_flag, application_metadata)
    # vuforia_return = connection.add_target(target_name, "./public/uploads/file.jpg", width, active_flag, application_metadata)
    puts vuforia_return.inspect
    connection_hash = JSON.parse(vuforia_return)
    @target.transaction_id = connection_hash["transaction_id"]
    @target.target_id = connection_hash["target_id"]
    @target.save

    @game = @company.games.create(game_params)
    @game.vuforia_name = target_name
    @game.logo = @target.image.url
    @game.save!

    @discount = @company.discounts.create(discount_params)
    @discount.game_id = @company.games.last.id
    @discount.save!


    puts @target.inspect
    puts @game.inspect
    puts @discount.inspect
    return render json: {"success": "success"}, status: 302
  end

  api :GET, '/games/:id/editor', "Récupérer les images"
  description <<-EOS
    === Status
      Requête pour que l'outil d'édition récupère les targets.
      si ok => 200
    === Réponse
        {
          "company": {
            "id": 9,
            "name": "playarshop",
            "logo": {
              "url": "/uploads/b1748668-89a1-4bdf-b937-ebb6ab66f4fd.gif"
            },
            "siret": "",
            "company_id_id": null,
            "user_id": 2,
            "created_at": "2017-01-01T18:25:51.495Z",
            "updated_at": "2017-01-01T21:36:01.327Z"
          },
          "games": [
            {
              "id": 15,
              "ref": "2",
              "name": "Name 1",
              "description": "Vise le verre1",
              "logo": "",
              "image": {
                "url": "/uploads/4c101277-3dc5-4d61-b2ab-0213ce46f99d.png"
              },
              "color1": "#8F3985",
              "color2": "#61E786",
              "perso1": "e53a1542e9170ccacefa71cc5fb9b3732577907a",
              "perso2": "Bloblo",
              "custom": "custom",
              "vuforia_name": "",
              "company_id": 1,
              "target_id": null,
              "created_at": "2017-01-01T20:53:10.250Z",
              "updated_at": "2017-01-01T21:00:56.306Z"
            },
            {
              "id": 16,
              "ref": "2",
              "name": "Name 2",
              "description": "Vise le verre2",
              "logo": "",
              "image": {
                "url": "/uploads/50187b4e-5e62-455c-8796-1c39b27d0ef0.png"
              },
              "color1": "#8F3985",
              "color2": "#61E786",
              "perso1": "e53a1542e9170ccacefa71cc5fb9b3732577907a",
              "perso2": "Bloblo",
              "custom": "custom",
              "vuforia_name": "",
              "company_id": 1,
              "target_id": null,
              "created_at": "2017-01-01T20:53:10.753Z",
              "updated_at": "2017-01-01T21:01:12.409Z"
            }
          ],
          "targets": [
            {
              "id": 27,
              "vuforia_name": "b5d8d934b0a6b04a59c3d60771a8142ccca33234",
              "transaction_id": "e53a1542e9170ccacefa71cc5fb9b3732577907a",
              "target_id": null,
              "image": {
                "url": "/uploads/78a5b18a-4091-4182-b49e-5fb3185069e5.png"
              },
              "path": null,
              "place": "rennes",
              "city": "RENNES",
              "discountChance": null,
              "discountRate": null,
              "company_id": 1,
              "game_id": null,
              "created_at": "2017-01-01T20:52:52.765Z",
              "updated_at": "2017-01-01T20:52:57.240Z"
            },
            {
              "id": 28,
              "vuforia_name": "fd8d1472ac166ce43f407b4b914e9ebcfe273bf0",
              "transaction_id": "e53a1542e9170ccacefa71cc5fb9b3732577907a",
              "target_id": null,
              "image": {
                "url": "/uploads/6dbd56c1-cf33-445d-8fc8-9e02fbd94a46.png"
              },
              "path": null,
              "place": "Germont",
              "city": "RENNES",
              "discountChance": null,
              "discountRate": null,
              "company_id": 1,
              "game_id": null,
              "created_at": "2017-01-01T20:52:57.282Z",
              "updated_at": "2017-01-01T20:53:09.743Z"
            }
          ]
    }
  EOS
  error :code => 401, :desc => "Vuforia name not found"
  param :id, String, :desc => "Game REF", :required => true
  param :logo_image, String, :desc => "Image du logo", :required => false
  param :target_image, String, :desc => "Image de la target", :required => false
  def editt
    puts params[:id]
    @shop = User.find_by(id: @current_user.id)
    puts @shop.inspect
    @company = Company.find_by(user_id: @shop.id)
    puts @company.inspect + '-----------------'
    @games = Game.where(perso1: params[:id])
    @targets = Target.where(transaction_id: params[:id])
    print @games.inspect
    return render :json => {
      :company =>@company.as_json(),
      :games =>@games.as_json(),
      :targets =>@targets.as_json()
    }, status: 200
      # @game = Game.find_by(id: params[:id])
    # # puts @game.inspect
    # # @company = Company.find_by(id: @game.company_id)
    # @target = Target.find_by(vuforia_name: @game.vuforia_name)
    # print params.inspect
    # t = Target.where(vuforia_name: params.require(:id))
    # targets = Target.where(transaction_id: t.first.transaction_id)
    # i = 0
    # index = 0
    # while (i < targets.size)
    #   print targets[i].inspect + "------------------"
    #   if (params.require(:id) == targets[i].vuforia_name)
    #     i = targets.size
    #   end
    #   i += 1
    #   index += 1
    # end
    # game = Game.where(perso1: t.first.transaction_id)
    # print game.inspect
    # @game = game[index - 1]
  end

  api :GET, '/recap/:id', "Résumé des informations "
  description <<-EOS
    === Status
      Requête pour que la confirmation de la création du jeu.
      si ok => 200
    === Réponse
      {
        "company": {
          "name": "playarshop",
          "logo": "base64_image"
        },
        "target": {
          "place": "rennes",
          "image": "base64_image"
        },
        "game": {
              "ref": 1,
              "name": "Ballons ",
              "description": "Eclates les ballons",
              "logo": "logo",
              "color1": "rouge",
              "color2": "bleu",
              "perso1": "Jeu de Jacquie",
              "perso2": "et Michèle",
              "custom": "custom"
          }
          "discount": {
                "success": "Bravo, vous avez gagné 42%",
                "fail": "Raté !"
          }
       }
  EOS
  error :code => 401, :desc => "Vuforia name not found"
  param :id, String, :desc => "ID du Game", :required => true
  param :logo_image, String, :desc => "Image du logo", :required => false
  param :target_image, String, :desc => "Image de la target", :required => false
  # def recap
  #   puts @current_user.inspect
  #   @shop = User.find_by(id: @current_user.id)
  #   @company = Company.find_by(id: @shop.company_id)
  #   puts @company.inspect
  #   @target = @company.targets.last
  #   puts @target.inspect
  #   @game = Game.find_by(id: @company.games.last.id)
  #   @discount = Discount.find_by(id: @company.discounts.last.id)
  # end
  def recap
    game_ref = params.require(:id)
    puts @current_user.inspect
    @user = User.find_by(id: @current_user.id)
    @target = Target.find_by(transaction_id: game_ref)
    @company = Company.find_by(user_id: @current_user.id)
    puts @target.inspect
    @game = Game.find_by(perso1: game_ref)
    @discount = Discount.find_by(game_ref: game_ref)
  end

  api :POST, '/games/:id', "Changer information du User"
  description <<-EOS
    === Request
    {
      "id": 4,
      "ref": "4",
      "name": "Chasse au tresor",
      "description": "Trouves toutes les cibles",
      "color1": "#8F3985",
      "color2": "#61E786",
      "company_id": 5,
      }
    === Réponse
  EOS
  error :code => 401, :desc => "Non autorisé"
  param :name, String, :desc => "Nom du jeu", :required => false
  def target_get_games
    puts @current_user.inspect
    @shop = User.find_by(id: @current_user.id)
    puts @shop.inspect
    @company = Company.find_by(id: @shop.company_id)
    @games = Game.find_by(id: @shop.company_id)
    puts @games.inspect
    @games = @company.games
  end

  # POST /games
  # POST /games.json
  api :POST, '/games', "Créer un ou plusieurs personnalisation de jeu"
  description <<-EOS
    === Requête
      Doit avoir une image
      Doit avoir le meme nombre de personnlisation que le nombre de Target
      {
        "game_ref": "target42",
        "game": {
          "ref": 2,
          "name": "Name 1",
          "description": "Vise le verre1",
          "color1": "#8F3985",
          "color2": "#61E786",
          "perso1": "Blabla",
          "perso2": "Bloblo",
          "custom": "custom"
          }
      }
    === Réponse
      Code 201 OK

  EOS
  error :code => 401, :desc => "Non autorisé"
  error :code => 400, :desc => "Pas d'image"
  param :game_ref, String, :desc => "Référence du jeu à personnaliser", :required => false
  param :game, Array, :desc => "Personnlisation du jeu", :required => false
  def create
    # @user = User.find(current_user.id)
    puts current_user.id
    @company = Company.find_by(user_id: current_user.id)
    print @company.inspect
    if @company.nil?
      return render :json => { "error": "no companyyyyy"}, status: 200
    end
    # print @company.inspect
    game_ref = params.require(:game_ref)
    # games = params.require(:game)
    # puts games.inspect
    # @user.company.games.create(g.permit(:ref, :name, :description, :logo, :color1, :color2, :perso1, :perso2, :custom, :discount, :vuforia_name))
    # games.each do |g|
    @company.games.create(game_params.permit(:ref, :name, :description, :logo, :image, :color1, :color2, :perso1, :perso2, :custom, :discount, :vuforia_name))
    @games = @company.games.last
    @games.perso1 = game_ref
    @games.image = @company.logo
    @games.save
    # end
    return render json: {"success": "Games created"}, status: 201
    # @game = Game.new(game_params)
    #
    # respond_to do |format|
    #   if @game.save
    #     format.html { redirect_to @game, notice: 'Game was successfully created.' }
    #     format.json { render :show, status: :created, location: @game }
    #   else
    #     format.html { render :new }
    #     format.json { render json: @game.errors, status: :unprocessable_entity }
    #   end
    # end
  end

  # PATCH/PUT /games/1
  # PATCH/PUT /games/1.json
  api :POST, '/games', "Modifier une personnalisation de jeu"
  description <<-EOS
    === Requête
      {
            "name": "Name 1",
            "description": "Vise le verre1",
            "color1": "#8F3985",
            "color2": "#61E786",
      }
    === Réponse
      Code 201 OK

  EOS
  error :code => 401, :desc => "Non autorisé"
  error :code => 400, :desc => "Pas d'image"
  def update
    # respond_to do |format|
    #   if @game.update(game_params)
    #     format.html { redirect_to @game, notice: 'Game was successfully updated.' }
    #     format.json { render :show, status: :ok, location: @game }
    #   else
    #     format.html { render :edit }
    #     format.json { render json: @game.errors, status: :unprocessable_entity }
    #   end
    # end
    @game = Game.find(params[:game_ref])
    @game.assign_attributes(game_params)
    @game.save
  end

  # DELETE /games/1
  # DELETE /games/1.json
  api :DELETE, '/games/1', "Supprimer un jeu"
  description <<-EOS
    === Requête
    === Réponse
      Code 201 OK

  EOS
  error :code => 401, :desc => "Non autorisé"
  def destroy
    @game.destroy
    respond_to do |format|
      format.html { redirect_to games_url, notice: 'Game was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_game
      if (@game = Game.find_by(vuforia_name: params[:id]))
        @game
      elsif (@game = Game.find_by(id: params[:id]))
        @game
      elsif (@game = Game.find_by(transaction_id: params[:id]))
        @game
      else
        render :json => {errors: "not found" }, status: 422
      end
    end

    def discount_params
      params.require(:discount).permit(:success, :fail)
    end

    def company_params
      params.require(:company).permit(:name, :siret, :logo)
    end

    def target_params
      params.require(:target).permit(:place, :image, :city)
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def game_params
      params.require(:game).permit(:ref, :name, :description, :logo, :color1, :color2, :perso1, :perso2, :custom, :discount, :vuforia_name)
    end
end
