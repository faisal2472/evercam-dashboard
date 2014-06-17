require 'spec_helper'

describe SharingController do
   describe 'POST /share/camera/:id' do
      let!(:camera) {
         create(:private_camera)
      }

      let!(:other_camera) {
         create(:private_camera)
      }

      let(:owner) {
         camera.owner
      }

      let(:credentials) {
         {api_id: owner.api_id, api_key: owner.api_key}
      }

      let(:parameters) {
         {:discoverable => false,
          :id =>           camera.exid,
          :public =>       false}
      }

      it "returns success for a valid request" do
         stub_request(:patch, "#{EVERCAM_API}cameras/#{camera.exid}.json").
            to_return(:status => 200, :body => "", :headers => {})

         post :update_camera, parameters.merge(credentials), {user: owner.email}
         expect(response.status).to eq(200)
         output = JSON.parse(response.body)
         expect(output.include?("success")).to eq(true)
         expect(output["success"]).to eq(true)
      end

      it "returns failure for an non-existent camera" do
         stub_request(:patch, "#{EVERCAM_API}cameras/blah.json").
            to_return(:status => 404, :body => "", :headers => {})

         parameters[:id]  = "blah"
         post :update_camera, parameters.merge(credentials), {user: owner.email}
         expect(response.status).to eq(200)
         output = JSON.parse(response.body)
         expect(output.include?("success")).to eq(true)
         expect(output.include?("message")).to eq(true)
         expect(output["success"]).to eq(false)
         expect(output["message"]).to eq("Failed to update camera permissions.")
      end

      it "returns failure for a camera that is owned by someone else" do
         stub_request(:patch, "#{EVERCAM_API}cameras/#{other_camera.exid}.json").
            to_return(:status => 403, :body => "", :headers => {})

         parameters[:id]  = other_camera.exid
         post :update_camera, parameters.merge(credentials), {user: owner.email}
         expect(response.status).to eq(200)
         output = JSON.parse(response.body)
         expect(output.include?("success")).to eq(true)
         expect(output.include?("message")).to eq(true)
         expect(output["success"]).to eq(false)
         expect(output["message"]).to eq("Failed to update camera permissions.")
      end

      it "returns failure if a public parameter is not specified" do
         parameters.delete(:public)
         post :update_camera, parameters.merge(credentials), {user: owner.email}
         expect(response.status).to eq(200)
         output = JSON.parse(response.body)
         expect(output.include?("success")).to eq(true)
         expect(output.include?("message")).to eq(true)
         expect(output["success"]).to eq(false)
         expect(output["message"]).to eq("Insufficient parameters provided.")
      end

      it "returns failure if a discoverable parameter is not specified" do
         parameters.delete(:discoverable)
         post :update_camera, parameters.merge(credentials), {user: owner.email}
         expect(response.status).to eq(200)
         output = JSON.parse(response.body)
         expect(output.include?("success")).to eq(true)
         expect(output.include?("message")).to eq(true)
         expect(output["success"]).to eq(false)
         expect(output["message"]).to eq("Insufficient parameters provided.")
      end
   end

   #----------------------------------------------------------------------------

   describe 'DELETE /share' do
      let!(:camera) {
         create(:private_camera)
      }

      let!(:share) {
         create(:private_share, camera: camera, user: camera.owner)
      }

      let(:owner) {
         camera.owner
      }

      let(:credentials) {
         {api_id: owner.api_id, api_key: owner.api_key}
      }

      let(:parameters) {
         {:camera_id => camera.exid,
          :share_id => share.id}
      }

      it 'returns failure if a camera_id is not specified' do
         parameters.delete(:camera_id)
         delete :delete, parameters.merge(credentials), {user: owner.email}
         expect(response.status).to eq(200)
         output = JSON.parse(response.body)
         expect(output.include?("success")).to eq(true)
         expect(output.include?("message")).to eq(true)
         expect(output["success"]).to eq(false)
         expect(output["message"]).to eq("Insufficient parameters provided.")
      end

      it 'returns failure if a share_id is not specified' do
         parameters.delete(:share_id)
         delete :delete, parameters.merge(credentials), {user: owner.email}
         expect(response.status).to eq(200)
         output = JSON.parse(response.body)
         expect(output.include?("success")).to eq(true)
         expect(output.include?("message")).to eq(true)
         expect(output["success"]).to eq(false)
         expect(output["message"]).to eq("Insufficient parameters provided.")
      end

      it 'returns failure if it gets a negative response from the API call' do
         stub_request(:delete, "#{EVERCAM_API}shares/cameras/#{camera.exid}.json?api_id=#{owner.api_id}&api_key=#{owner.api_key}&share_id=#{share.id}").
            to_return(:status => 403, :body => "", :headers => {})

         delete :delete, parameters.merge(credentials), {user: owner.email}
         expect(response.status).to eq(200)
         output = JSON.parse(response.body)
         expect(output.include?("success")).to eq(true)
         expect(output.include?("message")).to eq(true)
         expect(output["success"]).to eq(false)
         expect(output["message"]).to eq("Failed to delete camera share.")
      end

      it 'returns success if it gets a positive response from the API call' do
         stub_request(:delete, "#{EVERCAM_API}shares/cameras/#{camera.exid}.json?api_id=#{owner.api_id}&api_key=#{owner.api_key}&share_id=#{share.id}").
            to_return(:status => 200, :body => "", :headers => {})

         delete :delete, parameters.merge(credentials), {user: owner.email}
         expect(response.status).to eq(200)
         output = JSON.parse(response.body)
         expect(output.include?("success")).to eq(true)
         expect(output["success"]).to eq(true)
      end
   end

   #----------------------------------------------------------------------------

   describe 'POST /share' do
      let!(:camera) {
         create(:private_camera)
      }

      let!(:share) {
         create(:private_share, camera: camera, user: camera.owner)
      }

      let!(:owner) {
         camera.owner
      }

      let!(:shared_with) {
         create(:active_user)
      }

      let(:credentials) {
         {api_id: owner.api_id, api_key: owner.api_key}
      }

      let(:parameters) {
         {:camera_id => camera.exid,
          :permissions => "full",
          :email => shared_with.email}
      }

      it 'returns failure if a camera_id is not specified' do
         parameters.delete(:camera_id)
         post :create, parameters.merge(credentials), {user: owner.email}
         expect(response.status).to eq(200)
         output = JSON.parse(response.body)
         expect(output.include?("success")).to eq(true)
         expect(output.include?("message")).to eq(true)
         expect(output["success"]).to eq(false)
         expect(output["message"]).to eq("Insufficient parameters provided.")
      end

      it 'returns failure if an email address is not specified' do
         parameters.delete(:email)
         post :create, parameters.merge(credentials), {user: owner.email}
         expect(response.status).to eq(200)
         output = JSON.parse(response.body)
         expect(output.include?("success")).to eq(true)
         expect(output.include?("message")).to eq(true)
         expect(output["success"]).to eq(false)
         expect(output["message"]).to eq("Insufficient parameters provided.")
      end

      it 'returns failure if a permissions setting is not specified' do
         parameters.delete(:permissions)
         post :create, parameters.merge(credentials), {user: owner.email}
         expect(response.status).to eq(200)
         output = JSON.parse(response.body)
         expect(output.include?("success")).to eq(true)
         expect(output.include?("message")).to eq(true)
         expect(output["success"]).to eq(false)
         expect(output["message"]).to eq("Insufficient parameters provided.")
      end

      it 'returns failure if it gets a negative response from the API call' do
         stub_request(:post, "#{EVERCAM_API}shares/cameras/#{camera.exid}.json").
            with(:body => {"api_id"=>owner.api_id, "api_key"=>owner.api_key, "email"=>shared_with.email, "rights"=>"list,snapshot,grant~snapshot,view,grant~view,edit,grant~edit,grant~list"}).
            to_return(:status => 403, :body => '{"message": "Unauthorized", "code": "unknown_error", "context": []}', :headers => {})

         stub_request(:get, "#{EVERCAM_API}cameras/#{camera.exid}/live.json?api_id=#{owner.api_id}&api_key=#{owner.api_key}").
           to_return(:status => 200, :body => '{"data" : ""}', :headers => {})

         post :create, parameters.merge(credentials), {user: owner.email}
         expect(response.status).to eq(200)
         output = JSON.parse(response.body)
         expect(output.include?("success")).to eq(true)
         expect(output.include?("message")).to eq(true)
         expect(output["success"]).to eq(false)
         expect(output["message"]).to eq("Unauthorized")
      end

      it 'returns success if it gets a positive response from the API call' do
         stub_request(:post, "#{EVERCAM_API}shares/cameras/#{camera.exid}.json").
            with(:body => {"api_id"=>owner.api_id, "api_key"=>owner.api_key, "email"=>shared_with.email, "rights"=>"list,snapshot,grant~snapshot,view,grant~view,edit,grant~edit,grant~list"}).
            to_return(:status => 200, :body => '{"shares": [{"camera_id": "' + camera.exid + '", "id": 1000, "email": "' + shared_with.email + '"}]}', :headers => {})

         stub_request(:get, "#{EVERCAM_API}cameras/#{camera.exid}/live.json?api_id=#{owner.api_id}&api_key=#{owner.api_key}").
           to_return(:status => 200, :body => '{"data" : ""}', :headers => {})

         post :create, parameters.merge(credentials), {user: owner.email}
         expect(response.status).to eq(200)
         output = JSON.parse(response.body)
         expect(output.include?("success")).to eq(true)
         expect(output.include?("camera_id")).to eq(true)
         expect(output.include?("share_id")).to eq(true)
         expect(output.include?("permissions")).to eq(true)
         expect(output.include?("email")).to eq(true)
         expect(output["success"]).to eq(true)
         expect(output["camera_id"]).to eq(camera.exid)
         expect(output["permissions"]).to eq("full")
         expect(output["email"]).to eq(shared_with.email)
         expect(output["share_id"]).to eq(1000)
      end
   end

   #----------------------------------------------------------------------------

   describe 'DELETE /share/request' do
      let!(:camera) {
         create(:private_camera)
      }

      let!(:pending_share_request) {
         create(:pending_camera_share_request, camera: camera)
      }

      let(:owner) {
         camera.owner
      }

      let(:credentials) {
         {api_id: owner.api_id, api_key: owner.api_key}
      }

      let(:parameters) {
         {:camera_id => camera.exid,
          :email => pending_share_request.email}
      }

      it 'returns failure if a camera_id is not specified' do
         parameters.delete(:camera_id)
         delete :cancel_share_request, parameters.merge(credentials), {user: owner.email}
         expect(response.status).to eq(200)
         output = JSON.parse(response.body)
         expect(output.include?("success")).to eq(true)
         expect(output.include?("message")).to eq(true)
         expect(output["success"]).to eq(false)
         expect(output["message"]).to eq("Insufficient parameters provided.")
      end

      it 'returns failure if an email is not specified' do
         parameters.delete(:email)
         delete :cancel_share_request, parameters.merge(credentials), {user: owner.email}
         expect(response.status).to eq(200)
         output = JSON.parse(response.body)
         expect(output.include?("success")).to eq(true)
         expect(output.include?("message")).to eq(true)
         expect(output["success"]).to eq(false)
         expect(output["message"]).to eq("Insufficient parameters provided.")
      end

      it 'returns failure if it gets a negative response from the API call' do
         stub_request(:delete, "#{EVERCAM_API}shares/requests/#{camera.exid}.json?api_id=#{owner.api_id}&api_key=#{owner.api_key}&email=new.user3@nowhere.com").
            to_return(:status => 400, :body => '{"message": "Failed"}', :headers => {})

         delete :cancel_share_request, parameters.merge(credentials), {user: owner.email}
         expect(response.status).to eq(200)
         output = JSON.parse(response.body)
         expect(output.include?("success")).to eq(true)
         expect(output.include?("message")).to eq(true)
         expect(output["success"]).to eq(false)
         expect(output["message"]).to eq("Failed to delete camera share request.")
      end

      it 'returns success if it gets a positive response from the API call' do
         stub_request(:delete, "#{EVERCAM_API}shares/requests/#{camera.exid}.json?api_id=#{owner.api_id}&api_key=#{owner.api_key}&email=#{CGI.escape(pending_share_request.email)}").
            with(:headers => {'User-Agent'=>'Faraday v0.9.0'}).
            to_return(:status => 200, :body => "", :headers => {})

         delete :cancel_share_request, parameters.merge(credentials), {user: owner.email}
         expect(response.status).to eq(200)
         output = JSON.parse(response.body)
         expect(output.include?("success")).to eq(true)
         expect(output["success"]).to eq(true)
      end
   end

   #----------------------------------------------------------------------------

   describe 'PATCH /share/request' do
      let!(:share_request) {
         create(:pending_camera_share_request)
      }

      let(:camera) {
         share_request.camera
      }

      let(:owner) {
         camera.owner
      }

      let(:parameters) {
         {id: share_request.key, permissions: "full"}
      }

      let(:credentials) {
         {api_id: owner.api_id, api_key: owner.api_key}
      }

      it 'returns success if it gets a positive response from the API call' do
         stub_request(:patch, "#{EVERCAM_API}shares/requests/#{share_request.key}.json").
            with(:body => "api_id=#{owner.api_id}&api_key=#{owner.api_key}&rights=list%2Csnapshot%2Cview%2Cedit%2Cdelete").
            to_return(:status => 200, :body => "", :headers => {})

         patch :update_share_request, parameters.merge(credentials), {user: owner.email}
         expect(response.status).to eq(200)
         output = JSON.parse(response.body)
         expect(output.include?("success")).to eq(true)
         expect(output["success"]).to eq(true)
      end

      it 'returns failure if it gets a negative response from the API call' do
         stub_request(:patch, "#{EVERCAM_API}shares/requests/#{share_request.key}.json").
            with(:body => "api_id=#{owner.api_id}&api_key=#{owner.api_key}&rights=list%2Csnapshot%2Cview%2Cedit%2Cdelete").
            to_return(:status => 403, :body => '{"message": "Unauthorized"}', :headers => {})

         patch :update_share_request, parameters.merge(credentials), {user: owner.email}
         expect(response.status).to eq(200)
         output = JSON.parse(response.body)
         expect(output.include?("success")).to eq(true)
         expect(output.include?("message")).to eq(true)
         expect(output["success"]).to eq(false)
         expect(output["message"]).to eq("Failed to update share request. Please contact support.")
      end

      it 'returns failure if permissions are not specified' do
         parameters.delete(:permissions)
         patch :update_share_request, parameters.merge(credentials), {user: owner.email}
         expect(response.status).to eq(200)
         output = JSON.parse(response.body)
         expect(output.include?("success")).to eq(true)
         expect(output.include?("message")).to eq(true)
         expect(output["success"]).to eq(false)
         expect(output["message"]).to eq("Insufficient parameters provided.")
      end
   end

   #----------------------------------------------------------------------------

   describe 'PATCH /share' do
      let!(:share) {
         create(:private_share)
      }

      let(:camera) {
         share.camera
      }

      let(:owner) {
         camera.owner
      }

      let(:parameters) {
         {id: share.id, permissions: "full"}
      }

      let(:credentials) {
         {api_id: owner.api_id, api_key: owner.api_key}
      }

      it 'returns success if it gets a positive response from the API call' do
         stub_request(:patch, "#{EVERCAM_API}shares/cameras/#{share.id}.json").
            with(:body => {"api_id"=>owner.api_id, "api_key"=>owner.api_key, "rights"=>"list,snapshot,grant~snapshot,view,grant~view,edit,grant~edit,grant~list"}).
            to_return(:status => 200, :body => "", :headers => {})

         patch :update_share, parameters.merge(credentials), {user: owner.email}
         expect(response.status).to eq(200)
         output = JSON.parse(response.body)
         expect(output.include?("success")).to eq(true)
         expect(output["success"]).to eq(true)
      end

      it 'returns failure if it gets a negative response from the API call' do
         stub_request(:patch, "#{EVERCAM_API}shares/cameras/#{share.id}.json").
            with(:body => {"api_id"=>owner.api_id, "api_key"=>owner.api_key, "rights"=>"list,snapshot,grant~snapshot,view,grant~view,edit,grant~edit,grant~list"}).
            to_return(:status => 403, :body => '{"message": "Unauthorized"}', :headers => {})

         patch :update_share, parameters.merge(credentials), {user: owner.email}
         expect(response.status).to eq(200)
         output = JSON.parse(response.body)
         expect(output.include?("success")).to eq(true)
         expect(output.include?("message")).to eq(true)
         expect(output["success"]).to eq(false)
         expect(output["message"]).to eq("Failed to update share. Please contact support.")
      end

      it 'returns failure if permissions are not specified' do
         parameters.delete(:permissions)
         patch :update_share, parameters.merge(credentials), {user: owner.email}
         expect(response.status).to eq(200)
         output = JSON.parse(response.body)
         expect(output.include?("success")).to eq(true)
         expect(output.include?("message")).to eq(true)
         expect(output["success"]).to eq(false)
         expect(output["message"]).to eq("Insufficient parameters provided.")
      end
   end
end