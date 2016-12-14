require 'rho/rhocontroller'
require 'helpers/application_helper'
require 'helpers/browser_helper'

class ClipboardController < Rho::RhoController
  @layout = 'BluetoothChat/layout'
  include BrowserHelper
  include ApplicationHelper
  
  def index
    render :back => '/app'
  end

def clear_clipboard
   Rho::Clipboard.clear
   render :action => :index  
end

def set_clipboard
      puts 'set_text params = '+@params.to_s
      text = @params['text']
      Rho::Clipboard.setText text
      render :action => :index
  end

end
