module LoginsHelper
  def logins
    if @logins.any?
      render 'logins/partials/logins'
    else
      render 'logins/partials/no_logins'
    end
  end

  def login_modal(login)
    render 'logins/partials/show', login: login
  end

  def show_login(id)
    link_to id, '#' << id.to_s
  end

  def index_accounts(login)
    return login.accounts.count if login.status == 'inactive'
    link_to login.accounts.count, login_accounts_path(login.id)
  end

  def refresh_button(login)
    return if login.status == 'inactive' || Time.zone.now - Time.parse(login.next_refresh) < 0
    link_to 'settings_backup_restore', refresh_login_path(login.id),
            class: 'material-icons', id: 'refresh', title: 'Refresh', method: :put
  end

  def reconnect_button(id)
    link_to 'loop', '#',
            class: 'material-icons reconnect', title: 'Reconnect',
            data: { url: reconnect_login_path(id) }
  end

  def destroy_button(id)
    link_to 'power_settings_new', destroy_login_path(id),
            method: :delete,
            data: { confirm: 'The login with all its data will be destroyed' },
            class: 'material-icons', title: 'Destroy'
  end

  def error(error)
    error == 'Invalid login.' ? 'Invalid credentials.' : error
  end
end
