# encoding: utf-8

# Copyright © 2016
# Contributed by Raphaël Bleuse <raphael@bleuse.net>

class Hash
	def slice(*keys)
		keys.each_with_object(self.class.new) do |k, hash|
			hash[k] = self[k] if has_key?(k)
		end
	end

	def includes_keys?(*keys)
		keys.all? {|key| self.key? key}
	end
end

