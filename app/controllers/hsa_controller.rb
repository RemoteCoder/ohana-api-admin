class HsaController < ApplicationController
  before_filter :authenticate_user!

  #before_filter :days

  def index
    if admin?
      page = params[:page].present? ? params[:page] : 1
      @locations = Ohanakapa.locations(page: page)
    else
      domain = current_user.email.split("@").last
      @locations = Ohanakapa.search("search", :email => domain)
    end
  end

  def show
    id = params[:id].split("/")[-1]
    begin
      @location = Ohanakapa.location(id)
      unless location_domain_matches_user_domain?(@location) || admin?
        redirect_to root_url,
          :alert => "Sorry, you don't have access to that page."
      end
    rescue Ohanakapa::NotFound
      redirect_to "#{root_url}",
        alert: "Location not found! Please try another one." and return
    end

    @accessibility = [
      ["Information on CD", "cd"],
      ["Interpreter for the deaf", "deaf_interpreter"],
      ["Disabled Parking", "disabled_parking"],
      ["Elevator", "elevator"],
      ["Ramp", "ramp"],
      ["Disabled Restroom", "restroom"],
      ["Information on tape or in Braille", "tape_braille"],
      ["TTY", "tty"],
      ["Wheelchair", "wheelchair"],
      ["Wheelchair-accessible van", "wheelchair_van"]
    ]
    #@days = %w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday]

    # expires_in 3.minutes, :public => true

    # # etag based on @location object
    # # Rendering is not executed if etag is the same
    # if stale?(@location)
    #   respond_to do |format|
    #     format.html # show.html.haml
    #   end
    # end

  end

  def edit_services
    cat_ids = params[:category_ids]
    service_id = params[:service_id]
    location_id = params[:location_id]
    location_name = params[:location_name]
    org_id = params[:org_id]

    accessibility = params[:accessibility_options]
    kind = params[:kind] unless params[:kind].blank?
    emails = params[:emails]
    urls = params[:urls]

    # contacts
    names = params[:names]
    if names.blank?
      Ohanakapa.delete("locations/#{location_id}/contacts")
    end

    begin
      Ohanakapa.update_location(location_id,
        :accessibility => accessibility,
        :address => address,
        :contacts => contacts,
        :description => params[:description],
        :emails => emails,
        :faxes => faxes,
        :kind => kind,
        :mail_address => mail_address,
        :name => location_name,
        :phones => phones,
        :short_desc => params[:short_desc],
        :transportation => params[:transportation],
        :urls => urls
      )
    rescue Ohanakapa::BadRequest => e
      # Invalid Phone
      if e.to_s.include?("a valid US phone number")
        redirect_to request.referer,
          alert: "Please enter a valid US phone number" and return

      # Invalid Fax
      elsif e.to_s.include?("a valid US fax number")
        redirect_to request.referer,
          alert: "Please enter a valid US fax number" and return

      # Invalid Accessibility
      elsif e.to_s.include?("Accessibility is invalid")
        redirect_to request.referer,
          alert: "This website is sending invalid values for accessibility
            options. Please contact the website owner." and return

      # Missing both street and mailing address
      elsif e.to_s.include?("at least one address")
        redirect_to request.referer,
          alert: "Please enter at least one type of address" and return

      # Empty Street
      elsif e.to_s.include?("Street can't be blank")
        redirect_to request.referer,
          alert: "Please enter a street" and return

      # Empty City
      elsif e.to_s.include?("City can't be blank")
        redirect_to request.referer,
          alert: "Please enter a city" and return

      # Empty State
      elsif e.to_s.include?("State can't be blank")
        redirect_to request.referer,
          alert: "Please enter a state abbreviation" and return

      # Empty Zip
      elsif e.to_s.include?("Zip can't be blank")
        redirect_to request.referer,
          alert: "Please enter a ZIP code" and return

      # Invalid State
      elsif e.to_s.include?("State is too short")
        redirect_to request.referer,
          alert: "Please enter a valid state abbreviation" and return

      # Invalid Zip
      elsif e.to_s.include?("is not a valid ZIP code")
        redirect_to request.referer,
          alert: "Please enter a valid ZIP code" and return

      # Contact name missing
      elsif e.to_s.include?("Name can't be blank for Contact")
        redirect_to request.referer,
          alert: "Please enter a contact name" and return

      # Contact title missing
      elsif e.to_s.include?("Title can't be blank for Contact")
        redirect_to request.referer,
          alert: "Please enter a contact title" and return

      # Location name missing
      elsif e.to_s.include?("Name can't be blank")
        redirect_to request.referer,
          alert: "Location name can't be blank!" and return

      # Invalid email
      elsif e.to_s.include?("not a valid email")
        redirect_to request.referer,
          alert: "Please enter a valid email address" and return

      # Description missing
      elsif e.to_s.include?("Description can't be blank")
        redirect_to request.referer,
          alert: "Please enter a description" and return

      # Short description missing
      elsif e.to_s.include?("Short desc can't be blank")
        redirect_to request.referer,
          alert: "Please enter a short description" and return

      # Invalid URL
      elsif e.to_s.include?("is not a valid URL")
        redirect_to request.referer,
          alert: "Please enter a valid URL" and return

      # Kind missing
      elsif e.to_s.include?("Kind can't be blank")
        redirect_to request.referer,
          alert: "Please select a Kind" and return
      end

    end

    begin
      Ohanakapa.put("services/#{service_id}/", :query =>
        {
          :audience        => params[:audience],
          :description     => params[:description],
          :eligibility     => params[:eligibility],
          :fees            => params[:fees],
          :funding_sources => funding_sources,
          :how_to_apply    => params[:how_to_apply],
          :keywords        => keywords,
          :name            => params[:service_name],
          :service_areas   => service_areas,
          :wait            => params[:wait]
        }
      )
    rescue Ohanakapa::BadRequest => e
      # Wrong format for service area
      if e.to_s.include?("improperly formatted")
        redirect_to request.referer,
          alert: "At least one service area is improperly formatted,
        or is not an accepted city or county name. Please make sure all
        words are capitalized." and return
      end
    end

    Ohanakapa.replace_all_categories(service_id, cat_ids) if cat_ids
    #Ohanakapa.put("locations/#{location_id}/schedule", :query => { :schedule => schedule }) if schedule

    begin
      Ohanakapa.put("organizations/#{org_id}/", :query => { :name => params[:org_name] })
    rescue Ohanakapa::BadRequest => e
      if e.to_s.include?("Name can't be blank")
        redirect_to request.referer,
          alert: "Organization name can't be blank!" and return
      end
    end

    redirect_to "#{root_url}", notice: "Changes for #{location_name} successfully saved!" and return
  end

  private

  def admin?
    current_user.role == "admin"
  end

  def location_domain_matches_user_domain?(location)
    domain = current_user.email.split("@").last

    if location.key?(:emails)
      emails = location.emails.select { |email| email.include?(domain) }
    end

    if location.key?(:urls)
      urls = location.urls.select { |url| url.include?(domain) }
    end

    emails.present? || urls.present?
  end

end