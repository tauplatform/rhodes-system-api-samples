require 'rho/rhocontroller'

class AsyncUploadFileController < Rho::RhoController

  #GET /AsyncUploadFile
  def index

    #@@file_name = File.join(Rho::RhoApplication::get_model_path('app','AsyncUploadFile'), 'test_upload.png')
    @@file_name = File.join(Rho::RhoApplication::userFolder, 'test_upload.txt')
    unless File.exists?(@@file_name)
        write_data  = "this is rhodes test"
        f = File.new(@@file_name, "w")
        f.write(write_data)
        f.close
    end

    #options = {
    #    :url => 'http://5.19.220.82:8081/upload',
    #    :filename => @@file_name,
    #    :headers => {},
    #    :body => 'uploading file',
    #    :fileContentType => 'image/png'
    #}
    #Rho::Network.uploadFile(options, (url_for :action => :httpupload_callback))


    Rho::AsyncHttp.upload_file(
      #:url => 'http://dev.rhosync.rhohub.com/apps/SystemApiSamples/sources/client_log?client_id=19bdcf15-aca2-4e5a-9676-3c297c09bb11&device_pin=&log_name=',
      :url => 'http://taulogservice.herokuapp.com/client_log?log_name=rhodes-system-api-samples',
      :filename => @@file_name,
      :headers => {},
      :callback => (url_for :action => :httpupload_callback),
      :callback_param => "" )

    render :action => :wait
  end

  def get_res
    @@get_result
  end

  def get_error
    @@error_params
  end

  def httpupload_callback
    puts "httpupload_callback: #{@params}"

    if @params['status'] != 'ok'
        @@error_params = @params
        WebView.navigate ( url_for :action => :show_error )
    else
        @@get_result = "Success. File: " + @@file_name;
        WebView.navigate ( url_for :action => :show_result )
    end

  end

  def show_result
    render :action => :index, :back => '/app'
  end

  def show_error
    render :action => :error, :back => '/app'
  end

  def cancel_httpcall
    Rho::AsyncHttp.cancel( url_for( :action => :httpupload_callback) )

    @@get_result  = 'Request was cancelled.'
    render :action => :index, :back => '/app'
  end

end
