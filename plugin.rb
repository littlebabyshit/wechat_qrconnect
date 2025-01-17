
require 'omniauth/strategies/oauth2'

class OmniAuth::Strategies::WechatQRconnect < OmniAuth::Strategies::OAuth2
  option :name, "wechat_qrconnect"

  option :client_options, {
    :site => 'https://open.weixin.qq.com',
    :authorize_url => 'https://open.weixin.qq.com/connect/oauth2/authorize',
    :token_url => 'https://api.weixin.qq.com/sns/oauth2/access_token'
  }

  uid do
    @uid ||= begin
      access_token.params['unionid']
    end
  end

  info do
    {
      :nickname => raw_info['nickname'],
      :name => raw_info['nickname'],
      :image => raw_info['headimgurl'],
      :email => raw_info['email']

    }
  end

  extra do
    {
      :raw_info => raw_info
    }
  end

  def raw_info
    @raw_info ||= begin
      response = client.request(:get, "https://login.ceshiren.com/discourse/userinfo", :params => {
        :openid => uid,
        :access_token => access_token.token
      }, :parse => :json)
      response.parsed
    end
  end

  # customization
  def authorize_params
    super.tap do |params|
      params[:appid] = options.client_id
      params[:scope] = 'snsapi_userinfo'
    end
  end

  def token_params
    super.tap do |params|
      params[:appid] = options.client_id
      params[:secret] = options.client_secret
      params[:parse] = :json
      params.delete('client_id')
      params.delete('client_secret')
    end
  end
end

OmniAuth.config.add_camelization('wechat_qrconnect', 'WechatQRconnect')

# Discourse plugin
class WechatQRconnectAuthenticator < ::Auth::ManagedAuthenticator

  def name
    'wechat_qrconnect'
  end


  def log(info)
    Rails.logger.warn("OAuth2 Debugging: #{info}")
  end


  def register_middleware(omniauth)
    omniauth.provider :wechat_qrconnect, :setup => lambda { |env|
      strategy = env['omniauth.strategy']
      strategy.options[:client_id] = SiteSetting.wechat_qrconnect_client_id
      strategy.options[:client_secret] = SiteSetting.wechat_qrconnect_client_secret
    }
  end
end

auth_provider authenticator: WechatQRconnectAuthenticator.new
