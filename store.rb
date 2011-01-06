# A storage abstraction over memcached-client API.
#
require 'memcache'

class Store < MemCache
  def to_s
    "Store to #{self.servers}"
  end

  def exists?(key)
    self.get(key) != nil
  end

  def incr(key)
    n = super(key)
    return n if n
    self.add(key, '0', 0, true)
    self.incr(key)
  end

  def list_range(key, from, to)
    list = self.get(key, true) # Ex: nil or "+1+2+3".
    return [] unless list
    (list.split('+').drop(1) || []).slice(from, to - from + 1)
  end

  def push(key, value, prefix="+")
    # Lists are '+' delimited.
    if self.prepend(key, "#{prefix}#{value}").match("NOT_STORED")
      self.add(key, '', 0, true)
      self.push(key, value)
    end
  end

  def set_members_hash(key)
    s = self.get(key, true)         # Ex: nil or "+1+2-1"
    return {} unless s
    acts = s.split(/[^\+-]/)        # Ex: ["+", "+", "-"]
    vals = s.split(/[\+-]/).drop(1) # Ex: ["1", "2", "1"]
    m = {}
    i = acts.length - 1
    while i >= 0
      val = vals[i]
      if acts[i] == '+'
        m[val] = true
      else
        m.delete(val)
      end
      i = i - 1
    end
    m
  end

  def set_members(key)
    self.set_members_hash(key).keys()
  end

  def set_add(key, value)
    self.push(key, value, prefix="+")
  end

  def set_delete(key, value)
    self.push(key, value, prefix="-")
  end

  def set_member?(key, value)
    self.set_members_hash(key)[value]
  end
end

