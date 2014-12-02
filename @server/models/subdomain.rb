class Subdomain < ActiveRecord::Base
  has_many :proposals, :dependent => :destroy
  has_many :points, :dependent => :destroy
  has_many :opinions, :dependent => :destroy
  has_many :users, :dependent => :destroy
  has_many :comments, :dependent => :destroy

  has_attached_file :logo, :processors => [:thumbnail, :compression]
  has_attached_file :masthead, :processors => [:thumbnail, :compression]

  validates_attachment_content_type :masthead, :content_type => %w(image/jpeg image/jpg image/png image/gif)
  validates_attachment_content_type :logo, :content_type => %w(image/jpeg image/jpg image/png image/gif)

  class_attribute :my_public_fields
  self.my_public_fields = [:id, :name, :about_page_url, :notifications_sender_email, :app_title, :external_project_url, :assessment_enabled, :moderate_points_mode, :moderate_comments_mode, :moderate_proposals_mode, :has_civility_pledge]

  scope :public_fields, -> { select(self.my_public_fields) }

  def as_json(options={})
    options[:only] ||= Subdomain.my_public_fields
    json = super(options)
    json['moderated_classes'] = classes_to_moderate().map {|c| c.name}
    json['key'] = '/subdomain'
    if current_user.is_admin?
      json['roles'] = self.user_roles
    end
    json['branding'] = self.branding_info
    json
  end

  def host_without_subdomain
    host_with_port.split('.')[-2, 2].join('.')
  end

  # Subdomain-specific info
  # Assembled from a couple image fields and a serialized "branding" field.
  # 
  # This can be a bit annoying during development. Hardcode colors here
  # for different subdomains during development. 
  #
  # The serialized branding object can contain: 
  #   masthead_header_text
  #      This is bolded, white text in the header of the page.
  #   primary_color
  #      This is the sticky proposal header / header background. Should be dark.
  #   masthead_background_image
  #      If this is set, the image is applied as a height = 300px background 
  #      image covering the area
  #   logo
  #      A customer's logo. Shown in the footer if set. Isn't sized, just puts in whatever is uploaded. 
  #   light_masthead
  #      If the background image is dark or light; used to determine the header_text_color 
  def branding_info
    brands = JSON.parse(self.branding || "{}")

    if !brands.has_key?('primary_color') || brands['primary_color'] == ''
      brands['primary_color'] = '#E37765'
    end

    if brands.has_key?('light_masthead') && brands['light_masthead'] || !brands.has_key?('primary_color')
      brands['header_text_color'] = 'black'
    else
      brands['header_text_color'] = 'white'
    end

    brands['masthead'] = self.masthead_file_name ? self.masthead.url : nil
    brands['logo'] = self.logo_file_name ? self.logo.url : nil

    brands
  end

  def user_roles
    r = JSON.parse(roles || "{}")
    ['admin', 'moderator', 'evaluator'].each do |role|
      if !r.has_key?(role) || !r[role]
        r[role] = []
      end
    end
    r
  end

  def set_roles(new_roles)
    self.roles = JSON.dump(new_roles)
    self.save
  end

  def self.all_themes
    Dir['app/assets/themes/*/'].map { |a| File.basename(a) }
  end

  def classes_to_moderate

    classes = []

    if moderate_points_mode > 0
      classes << Point
    end
    if moderate_comments_mode > 0
      classes << Comment
    end
    if moderate_proposals_mode > 0
      classes << Proposal
    end

    classes

  end

end