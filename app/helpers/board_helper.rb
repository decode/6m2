module BoardHelper
  include Acl9Helpers

  access_control :super? do
    allow :super
  end
  access_control :admin? do
    allow :admin, :super
  end
  access_control :manager? do
    allow :manager
  end
  access_control :user? do
    allow :user
  end
  access_control :guest? do
    allow :guest
  end
end
