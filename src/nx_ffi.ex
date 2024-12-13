defmodule :nx_ffi do
  def tensor(x, format), do:  Nx.tensor(x, type: format)
end
