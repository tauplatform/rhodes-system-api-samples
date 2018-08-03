require 'rho/rhocontroller'
require 'rho/rhobluetooth'


class BluetoothDemoController < Rho::RhoController
  @layout = 'BluetoothDemo/layout'

  $device_name = nil
  $connected_device_name = nil
  $current_status = 'Not connected'
  $history = '---'
  $is_custom_connecting_in_progress = false
  $server_name = ''
  $session = nil

  def index
    puts 'BluetoothDemoController.index'
    $device_name = Rho::BluetoothConnection.deviceName
    puts "$device_name=" + $device_name.to_s
    render
  end

  def execute_js(js)
      WebView.execute_js(js)
  end

  def on_send
    puts 'BluetoothDemoController.on_send'
    message = @params['message']
    puts 'history ' + $history.to_s
    $history = message + '\n'+$history
    #Rho::BluetoothSession.write_string($connected_device_name, message)
    connection = Rho::BluetoothConnection.getConnectionByID($connected_device_name)
    connection.writeString(message)
    execute_js('setHistory("'+$history+'");')

  end

  def example_send_byte_array
    ar = [21, 22, 23, 5, 777]
    #Rho::BluetoothSession.write($connected_device_name, ar)
    connection = Rho::BluetoothConnection.getConnectionByID($connected_device_name)
    connection.writeData(ar)
  end

  def on_connect_server
    puts 'BluetoothDemoController.on_connect_server'
    if $connected_device_name == nil
       puts 'BluetoothDemoController::on_connect()'
       $current_status = 'Connecting ...'
       execute_js('setStatus("'+$current_status+'");')
       #Rho::BluetoothManager.create_session(Rho::BluetoothManager::ROLE_SERVER, url_for(:action => :create_session_callback) )
       Rho::BluetoothConnection.createConnection(Rho::BluetoothConnection::ROLE_SERVER, url_for(:action => :create_session_callback))
    else
        on_disconnect
    end
  end

  def on_connect_client
    puts 'BluetoothDemoController.on_connect_client'
    if $connected_device_name == nil
       puts 'BluetoothDemoController::on_connect()'
       $current_status = 'Connecting ...'
       execute_js('setStatus("'+$current_status+'");')
       #Rho::BluetoothManager.create_session(Rho::BluetoothManager::ROLE_CLIENT, url_for(:action => :create_session_callback) )
       Rho::BluetoothConnection.createConnection(Rho::BluetoothConnection::ROLE_CLIENT, url_for(:action => :create_session_callback))
    else
        on_disconnect
    end
  end

  def on_connect_custom_server
    puts 'BluetoothDemoController.on_connect_custom_server'
    if ($connected_device_name == nil) && (!$is_custom_connecting_in_progress)
       puts 'BluetoothDemoController::on_connect()'
       $current_status = 'Connecting ...'
       execute_js('setStatus("'+$current_status+'");')
       $is_custom_connecting_in_progress = true
       #Rho::BluetoothManager.create_server_and_wait_for_connection(url_for(:action => :create_session_callback))
       Rho::BluetoothConnection.createServerConnection(url_for(:action => :create_session_callback))

       execute_js('setCustomButtonCaption("Cancel");')
    else
        if ($connected_device_name == nil)
               Rho::BluetoothConnection.stopCurrentConnectionProcess
               $connected_device_name = nil
               $current_status = 'Cancelled'
               execute_js('setStatus("'+$current_status+'");')
               execute_js('restoreCustomButtonCaption();')
               $is_custom_connecting_in_progress = false
        else
               on_disconnect
        end
    end
  end

  def on_connect_custom_client
    puts 'BluetoothDemoController.on_connect_custom_client'
    if ($connected_device_name == nil) && (!$is_custom_connecting_in_progress)
       puts 'BluetoothDemoController::on_connect()'
       $current_status = 'Connecting ...'
       execute_js('setStatus("'+$current_status+'");')
       $is_custom_connecting_in_progress = true
       #Rho::BluetoothManager.create_client_connection_to_device($server_name, url_for(:action => :create_session_callback))
       Rho::BluetoothConnection.createClientConnection($server_name, url_for(:action => :create_session_callback))
       execute_js('setCustomButtonCaption("Cancel");')
    else
        if ($connected_device_name == nil)
               Rho::BluetoothConnection.stopCurrentConnectionProcess
               $connected_device_name = nil
               $current_status = 'Cancelled'
               execute_js('setStatus("'+$current_status+'");')
               execute_js('restoreCustomButtonCaption();')
               $is_custom_connecting_in_progress = false
        else
               on_disconnect
        end
    end
  end

  def on_disconnect
    puts 'BluetoothDemoController.on_disconnect'
    if $connected_device_name == nil
       Alert.show_popup "You are not connected now !"
    else
       #Rho::BluetoothSession.disconnect($connected_device_name)
       connection = Rho::BluetoothConnection.getConnectionByID($connected_device_name)
       connection.disconnect
       $connected_device_name = nil
       $current_status = 'Disconnected'
       execute_js('setStatus("'+$current_status+'");')
       execute_js('restoreButtonCaption();')
       execute_js('restoreCustomButtonCaption();')

     end
  end

  def on_change_name
    if $connected_device_name != nil
       Alert.show_popup "You cannot change name while you connected !"
    else
       $device_name = @params['device_name']
       #Rho::BluetoothManager.set_device_name($device_name)
       Rho::BluetoothConnection.deviceName = $device_name
     end
  end

  def on_change_server_name
    puts "on_change_server_name with " + @params['device_name'].to_s
    $server_name = @params['device_name']
  end

  def create_session_callback
    puts 'BluetoothDemoController::create_session_callback'
    puts 'status = ' + @params['status']
    $connected_device_name = @params['connectionID']
    puts 'connectionID = ' + $connected_device_name
    if @params['status'] == Rho::BluetoothConnection::STATUS_OK
      $current_status = 'Connected to ['+$connected_device_name+']'
      if System::get_property('platform') == 'APPLE' ||
         System::get_property('platform') == 'ANDROID' ||
         System::get_property('platform') == 'WINDOWS'

          $server_name = $connected_device_name
          execute_js('setServerName("'+$server_name+'");')
      end
      #Rho::BluetoothSession.set_callback($connected_device_name, url_for(:action => :session_callback))
      connection = Rho::BluetoothConnection.getConnectionByID($connected_device_name)
      connection.setCallback(url_for(:action => :session_callback))

      #Rho::BluetoothSession.write_string($connected_device_name, 'Hello another Bluetooth device !')
      if ($is_custom_connecting_in_progress)
             execute_js('setCustomButtonCaption("Disconnect");')
      else
             execute_js('setButtonCaption("Disconnect");')
      end
    else
       if @params['status'] == Rho::BluetoothConnection::STATUS_CANCEL
         $current_status = 'Cancelled by User'
       else
         $current_status = 'Error with Connection'
       end
    end
    execute_js('setStatus("'+$current_status+'");')

    $is_custom_connecting_in_progress = false
  end

  def on_data_received
    puts 'BluetoothDemoController::on_data_received START'
    received = ""
    connection = Rho::BluetoothConnection.getConnectionByID($connected_device_name)
    while connection.status > 0
       message = connection.readString
       received = received + message
    end
    if received.length > 0
        puts 'BluetoothDemoController::on_data_received MESSAGE='+received
        $history = $connected_device_name+':'+ received + '\n'+$history
        execute_js("setHistory('"+$history+"');")
    end
    puts 'BluetoothDemoController::on_data_received FINISH'

  end

  def example_receive_byte_array
      connection = Rho::BluetoothConnection.getConnectionByID($connected_device_name)
       ar = connection.readData
       puts ar
  end

  def session_callback
    puts 'BluetoothDemoController::session_callback'
    cdn = @params['connectionID']
    status = @params['status']
    puts 'connected_device_name = ' + cdn
    puts 'event_type = ' + status
    if status == Rho::BluetoothConnection::CONNECTION_STATUS_INPUT_DATA_RECEIVED
       # receive data
       on_data_received
    else
       if status == Rho::BluetoothConnection::CONNECTION_STATUS_DISCONNECTED
          $connected_device_name = nil
          $current_status = 'Disconnected'
          execute_js('setStatus("'+$current_status+'");')
          execute_js('restoreButtonCaption();')
          execute_js('restoreCustomButtonCaption();')

       else
          $current_status = 'Error occured !'
          $connected_device_name = nil
          execute_js('setStatus("'+$current_status+'");')
          execute_js('restoreButtonCaption();')
          execute_js('restoreCustomButtonCaption();')

       end
    end
  end

  def on_close
    puts 'BluetoothDemoController::on_close()'
    Rho::BluetoothConnection.disableBluetooth
  end

end
