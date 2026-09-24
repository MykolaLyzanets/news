# frozen_string_literal: true

module Admin
  class SettingsController < BaseController
    def show
      @setting = SiteSetting.current
    end

    def update
      @setting = SiteSetting.current
      if @setting.update(setting_params)
        redirect_to admin_settings_path, notice: 'Settings saved'
      else
        render :show, status: :unprocessable_entity
      end
    end

    def sync_news_links
      unless GoogleSheets::Config.configured?
        redirect_to admin_settings_path, alert: 'Додайте JSON service account у налаштуваннях'
        return
      end

      GoogleSheets::NewsLinks.new.sync_all!
      redirect_to admin_settings_path, notice: 'All live news links were sent to Google Sheets'
    rescue Google::Apis::Error, GoogleSheets::Client::Error => e
      redirect_to admin_settings_path, alert: e.message
    end

    private

    def setting_params
      params.require(:site_setting).permit(:google_sheets_service_account_json)
    end
  end
end
