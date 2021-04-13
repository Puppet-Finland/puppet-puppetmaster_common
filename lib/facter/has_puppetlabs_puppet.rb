Facter.add('has_puppetlabs_puppet') do
  setcode do
    if File.file?('/opt/puppetlabs/bin/puppet')
      true
    else
      false
    end
  end
end
