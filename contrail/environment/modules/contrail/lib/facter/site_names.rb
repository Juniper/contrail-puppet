require 'facter'

Facter.add(:site_names) do
    setcode do
        site_names = []
        entries = Dir["/etc/apache2/sites-enabled/*"]
        entries.each do |entry|
            site_names.push(File.basename(entry))
            end
        site_names
    end
end
