require "#{File.join(File.dirname(__FILE__),'..','spec_helper.rb')}"

describe 'openvpn::tunnel' do

  let(:title) { 'openvpn::tunnel' }
  let(:node) { 'rspec.example42.com' }
  let(:facts) { { :arch => 'i386' } }
  let(:params) {
    { 'enable'    => 'true',
      'name'      => 'mytunnel',
      'auth_type' => 'key',
      'remote'    => '1.1.1.1',
      'port'      => '1150',
      'auth_key'  => 'mykey',
    }
  }

  describe 'Test configuration file creation' do
    it 'should create a openvpn::tunnel configuration file' do
      should contain_file('openvpn_mytunnel.conf').with_ensure('present')
    end
    it 'should populate correctly the openvpn::tunnel configuration file' do
      should contain_file('openvpn_mytunnel.conf').with_content(/secret \/etc\/openvpn\/mytunnel\.key/)
    end
    it 'should create a key file when auth_key is provided' do
      should contain_file('openvpn_mytunnel.key').with_source(/mykey/)
    end
  end

  describe 'Test many remote configuration' do
    let(:params) { {
      :name   => 'mytunnel',
      :mode   => 'client',
      :port   => '1150',
      :remote => ['vpn1.example42.com','vpn2.example42.com'],
    } }
    it { should contain_file('openvpn_mytunnel.conf').with_content(/remote vpn1.example42.com 1150\nremote vpn2.example42.com 1150/) }
  end

  describe 'Test Monitoring Tools Integration' do
    let(:facts) { {:monitor => true, :monitor_tool => "puppi", :monitor_target => "2.2.2.2" } }

    it 'should generate monitor defines' do
      should contain_monitor__process('openvpn_mytunnel_process').with_tool('puppi')
    end
  end

  describe 'Test client compress configuration' do
    let(:params) { {
      :name     => 'mytunnel',
      :mode     => 'client',
      :compress => true,
    } }
    it { should contain_file('openvpn_mytunnel.conf').with_content(/comp-lzo/) }
  end

  describe 'Test Monitoring Tools Integration' do
    let(:facts) { {:monitor => true, :monitor_tool => "puppi", :monitor_target => "2.2.2.2" } }

    it 'should generate monitor defines' do
      should contain_monitor__process('openvpn_mytunnel_process').with_tool('puppi')
    end
  end

  describe 'Test client keepalive configuration' do
    let(:params) { {
      :name              => 'mytunnel',
      :mode              => 'client',
      :keepalive         => true,
      :keepalive_freq    => '42',
      :keepalive_timeout => '4242',
    } }
    it { should contain_file('openvpn_mytunnel.conf').with_content(/keepalive 42 4242/) }
  end

  describe 'Test Monitoring Tools Integration' do
    let(:facts) { {:monitor => true, :monitor_tool => "puppi", :monitor_target => "2.2.2.2" } }

    it 'should generate monitor defines' do
      should contain_monitor__process('openvpn_mytunnel_process').with_tool('puppi')
    end
  end

  describe 'Test Firewall Tools Integration' do
    let(:facts) { {:firewall => true, :firewall_tool => "iptables" } }

    it 'should generate correct firewall define' do
      should contain_firewall('openvpn_mytunnel_tcp_1150').with_tool('iptables')
    end
  end

end
