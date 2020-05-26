
require 'httparty'
require 'json'
require "awesome_print"



#Get auth code 
#https://oauth.pipedrive.com/oauth/authorize?client_id=6bb43b8d7d7401c3&redirect_uri=http://localhost:8080/pipedrive/auth/callback


#stocker le auth_code depuis l'url (copier coller à la main) et le mettre ds variable auth_code



def pipedrive_get_access_token(auth_code)
    request = HTTParty.post(
        'https://oauth.pipedrive.com/oauth/token', 
        body: {

        :grant_type => "authorization_code",
        :code => auth_code,
        :redirect_uri => "http://localhost:8080/pipedrive/auth/callback"} ,


        headers: {
            "Content-type": "application/x-www-form-urlencoded"
        },
    
        basic_auth:{
                :username => "6bb43b8d7d7401c3",
                :password => "806926e0d0da320f34960a6589ff62f12686fb1d"
                }

        )
        
        credentials = JSON.parse(request.body)

        #On créé aussi une datasource pour les tests

        @datasource = {
            source_type: "Pipedrive",
            name: "¨Pipedrive : " + "Louis",
            credentials: credentials,
            user_id: 1
        }

        puts @datasource
    end


    

#récupérer l'access token grace a la fonction pipedrive_get_access_token (fait ds le callback pipedrive avant la création de la metric ou de l'instance pipedrive)




            
    class PipedriveConnector
        include HTTParty
     
        def initialize(datasource,metric=nil)
        @@access_token = datasource[:credentials]["access_token"]
        @refresh_token = datasource[:credentials]['refresh_token']
        @validity_date = datasource[:credentials]['created_at'] #finir apres, boléen date de validation 
        @api_domain = datasource[:credentials]['api_domain']
        @metric = metric

        end


        def compute_metric               
             metric_result =HTTParty.get("#{@api_domain}/#{@metric[:configuration][:type]}?#{params()}" , headers: {"Authorization" => "Bearer #{@@access_token}"})

            infos = get_infos(metric_result)
            infos.each do |key, value|
                puts value["value"]
                
            end
               
               
        
        end
    
       

        def get_all_filters
            filters = HTTParty.get("#{@api_domain}/filters" , headers: {"Authorization" => "Bearer #{@@access_token}"})
            
        end
        
        #permet de créer les params à ajouter à l'endpoint lors du get à l'api pipedrive
        def params()
            params = []
            @string = ""
            @metric[:configuration][:params].each { |key,value|  params <<  "#{key.to_s}=#{value.to_s}" }
            params.each do |elements|
            @string <<  elements + "&"
            end
            return @string.delete_suffix('&')
        end
        


        #permet de parser les infos pour un deal
        def get_infos(request)

            won_deal_infos_hash = Hash.new
            
            i=0
                while i < request['data'].count
                    new_hash = Hash.new
                   new_hash["title"] =  request['data'][i]["title"]
                   new_hash["id"] =  request['data'][i]["id"]
                   new_hash["value"]=request['data'][i]["value"] 
                   new_hash["status"] = request['data'][i]["status"]
                   new_hash["formatted_value"] =request['data'][i]["formatted_value"]
                   new_hash["add_time"] =  request['data'][i]["add_time"]
                   new_hash["owner_name"] =  request['data'][i]["owner_name"]
                   
                   
                   won_deal_infos_hash[i] = new_hash
                   i+=1    
                   
                end 
           
            return won_deal_infos_hash
        
        end


        def refresh_token()
            request = HTTParty.post(
                'https://oauth.pipedrive.com/oauth/token', 
                body: {
                        :grant_type => "refresh_token",
                        :refresh_token => "#{@refresh_token}", 
               },
                headers: {"Content-type": "application/x-www-form-urlencoded"},
                
                basic_auth:{
                        :username => "6bb43b8d7d7401c3",
                        :password => "806926e0d0da320f34960a6589ff62f12686fb1d"
                        })
                
                new_credentials = JSON.parse(request.body)
        
                @@access_token =  new_credentials["access_token"]
                
            end

       
        
end



datasource = {:source_type=>"Pipedrive",
     :name=>"\u00A8Pipedrive : Louis",
      :credentials=>{
                "access_token"=>"7456572:11338568:57a4d2e86116cdb47d5cc69ea947c11daeb61e4a",
                "token_type"=>"Bearer", "expires_in"=>3599,
                "refresh_token"=>"7456572:11338568:0fa0a15a5f8bf178eec12f58bc33ba50cf657de2",
                "scope"=>"base,deals:full,mail:full,activities:full,contacts:full,products:full,users:read,recents:read,search:read,admin",
                "api_domain"=>"https://droyd-sandbox.pipedrive.com"},
 :user_id=>1}

 datasource[:credentials]

 
 
metric = { :name=>"Average value of Won deals last quarter",
           :datasource_id=>2,

           :configuration=>{         
        
        
            :type=>"deals",
            :params=>{
                "status"=>"won",
                
                
                
                
               
                               
            },
            :Aggregate_function=>"average",
            :Aggregate_function_field=>"value"
           
            }
        

        }



pipedrive = PipedriveConnector.new(datasource,metric)
pipedrive.refresh_token
ap pipedrive.compute_metric

"
aggregate_function = {
    Average (i.e., arithmetic mean)
Count
Maximum
Median
Minimum
Mode
Range
Sum
}"












#"id":1,"name":"All open deals","active_flag":true,"type":"deals","temporary_flag":null,"user_id":11338568,
#"add_time":"2020-03-10 14:12:54","update_time":null,"visible_to":"7","custom_view_id":null}