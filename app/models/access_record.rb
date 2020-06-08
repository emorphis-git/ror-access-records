class AccessRecord < ApplicationRecord
  enum access_type: [:FTP, :SQL, :SSH, :SFTP, :URL, :RDP, :SMTP, :TCP, :UDP, :SMB, :NFS, :LDAP  ]

  ACCESS_TYPE = { 'FTP' => 'FTP', 'SQL' => 'SQL', 'SSH' => 'SSH', 'SFTP' => 'SFTP', 'URL' => 'URL', 'RDP' => 'RDP', 'SMTP' => 'SMTP', 'TCP' => 'TCP', 'UDP' => 'UDP', 'SMB' => 'SMB', 'NFS' => 'NFS', 'LDAP' => 'LDAP'  }

  validates :client_id, :project_id ,:access_type ,presence: true 
  validates :host_address, presence: true
  validates :port, presence: true, numericality: { only_integer: true }
  validates :username, presence: true, length: { in: 2..100}
  validates :password, presence: true, length: { in: 2..100}

  belongs_to :client
  belongs_to :project

  scope :visible, ->(*args) do
    includes(:project)
      .references(:projects)
      .merge(Project.allowed_to(args.first || User.current, :view_access_records))
  end

  def self.latest_for(user, count: 20)
    scope = newest_first
            .visible(user)

    if count > 0
      scope.limit(count)
    else
      scope
    end
  end

  # table_name shouldn't be needed :(
  def self.newest_first
    order "#{table_name}.id DESC"
  end

  def visible?(user = User.current)
    !user.nil? && user.allowed_to?(:view_news, project)
  end
end
