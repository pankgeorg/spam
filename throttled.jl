### A Pluto.jl notebook ###
# v0.14.1

using Markdown
using InteractiveUtils

# ╔═╡ bf71daae-3d34-11eb-1ca1-d9b018e99f18
# ═execution_barrier
"Create a throttled function, which calls the given function `f` at most once per given interval `max_delay`.

It is _leading_ (`f` is invoked immediately) and _not trailing_ (calls during a cooldown period are ignored)."
function throttled(f::Function, max_delay::Real, initial_offset::Real=0)
	local last_run_at = time() - max_delay + initial_offset
	# return f
	() -> begin
		now = time()
		if now - last_run_at >= max_delay
			f()
			last_run_at = now
		end
		nothing
	end
end

# ╔═╡ dde97532-3d34-11eb-030d-054b47086952
function log()
	@info "Hello" rand()
end

# ╔═╡ fac02af2-3d34-11eb-17b8-61505c641f17
log()

# ╔═╡ 55752812-3d35-11eb-3962-91f60f0b8219
t = throttled(log, 2, 5)

# ╔═╡ 5d2b13be-3d35-11eb-2e47-51223a2a47bf
t()

# ╔═╡ 0aec4a64-3d35-11eb-3d3b-a306558f610c
let
	a = time()
	b = sqrt.([200])
	time() - a
end

# ╔═╡ 880ba494-3b1f-4d1d-95b4-469a7178726c
md"""
# With cooldown delay
"""

# ╔═╡ 8a1a1300-5f32-445b-8ead-53e700fa186c
"Create a throttled function, which calls the given function `f` at most once per given interval `max_delay`.

It is _leading_ (`f` is invoked immediately) and _not trailing_ (calls during a cooldown period are ignored).

An optional third argument sets an initial cooldown period, default is `0`. With a non-zero value, the throttle is no longer _leading_."
function throttled2(f::Function, max_delay::Real, initial_offset::Real=0)
	local last_run_at = time() - max_delay + initial_offset
	# return f
	() -> begin
		now = time()
		if now - last_run_at >= max_delay
			f()
			last_run_at = now
		end
		nothing
	end
end

# ╔═╡ d97c1432-197f-4fed-8ed9-f2c30612aaca
md"""
## Let's test this

- we get a ref
- fx adds one to that
- we run a long iteration and call `tf_fn` 5.000.000 times.
- the time it runs should be throttled at 10 second
- so the ref should be incremented by 10x(seconds) -- see bottom right 


"""

# ╔═╡ 70e27d8e-1d56-48ad-90be-6836d6d68292
ref = Ref(0)

# ╔═╡ d18d86d4-bf7a-4819-afe6-a0d24586546b
ref[]=0

# ╔═╡ a1c6af58-10d6-45f6-ba0b-b1a45a0d2c56
fx(i=-1) = begin
	ref[] = ref[]+1
end

# ╔═╡ 315f67bc-f989-422f-ae60-b6e913c483f6
md"""
Flux
"""

# ╔═╡ 0cdc9124-fb04-441d-bac7-66c83e0c1a7b
md"""
thread safe-flux
"""

# ╔═╡ ffbeb451-e5f2-41c5-a499-c3560f07bac4
md"""
Simple
"""

# ╔═╡ 8ecfbbe9-d6f7-4414-afc1-4189abbb0354
md"""
## Test Flux
"""

# ╔═╡ 92dee53d-b932-4371-a307-6eece37fc798
md"""
## Test Thread-Safe Flux
"""

# ╔═╡ ae857899-7db3-4bd5-8280-e6128731d234
2.6/0.15

# ╔═╡ ffd931d6-be9b-4460-9526-d61bd49b23fc
md"""
## My implementation
"""

# ╔═╡ c84a44f0-2422-489e-b16f-d5dc691f3149
function throttle(f::Function, delay::Real)
	skip = false
	return () -> begin
		f();
		skip = false
	end, () -> begin
		yield()
		if !skip
			skip = true
			@async begin
				sleep(delay);
				skip && f();
				skip=false
			end
		end
		yield()
	end
end

# ╔═╡ 472f989d-8632-4986-bf26-d78a2c7b723a
flush, fn = throttle(fx, 0.1)

# ╔═╡ 0cb5ae68-dca4-411a-b13d-71c560f1f1ae
function throttle_ts(f, timeout; leading=false, trailing=true)
	tlock = ReentrantLock()
	iscoolnow = true
	later = false
	
	function flush()
		lock(tlock)
		try
			later = false
			f()
		finally
			unlock(tlock)
		end
	end

	function throttled()
		yield()
		if iscoolnow
			if leading
				flush()
			else
				later = true
			end
			iscoolnow = false
			@async try
				while (sleep(timeout); later)
					flush()
				end
			finally
				iscoolnow = true
			end
		elseif trailing
			later = true
		end
	end

	return throttled, flush
end

# ╔═╡ a2bae643-ad0f-44f1-9e6b-b2ae027c70b0
ts_fn, ts_flush = throttle_ts(fx, 0.1; leading = true, trailing=false)

# ╔═╡ 72574513-5cf2-49bf-9a37-e34004501872
begin
	ref[] = 0
	for i in 1:5_000_000
		ts_fn()
	end
	ts_flush()
	ref[]
end

# ╔═╡ 0ee72c37-862f-4750-9ff6-ab57f77bad5c
md"""
## Flux implementation
"""

# ╔═╡ 9e461a14-0fc9-4d0f-bae3-5b8a1814ee44
"https://github.com/FluxML/Flux.jl/blob/master/src/utils.jl#L673"
function tf_throttle(f, timeout; leading=true, trailing=false)
  cooldown = true
  later = nothing
  result = nothing

  function flush(args...; kwargs...)
	later = nothing
	f(args...; kwargs...)
  end

  function throttled(args...; kwargs...)
    yield()

    if cooldown
      if leading
        result = f(args...; kwargs...)
      else
        later = () -> f(args...; kwargs...)
      end

      cooldown = false
      @async try
        while (sleep(timeout); later != nothing)
          later()
          later = nothing
        end
      finally
        cooldown = true
      end
    elseif trailing
      later = () -> (result = f(args...; kwargs...))
    end

    return result
  end

  return throttled, flush
end



# ╔═╡ 8b59d910-b93e-40c0-bb0d-16cb2a6d3fcc
tf_fn, tf_flush = tf_throttle(fx, 0.1)

# ╔═╡ 37611481-6432-4de5-8f37-df85bc9414e8
begin
	ref[] = 0
	for i in 1:5_000_000
		tf_fn(i)
	end
	ref[]
end

# ╔═╡ 721c9881-b2c6-4d57-a847-1d08dee6f26c
md"""
## Thread safe adjustment of FluxML implementation

*Guarantees that the function will be run "sequentially"*
"""

# ╔═╡ 35c23dc6-2c79-4ac1-b085-97d7298c2b97
"""Throttled with thread safety
That means that the function is called every ` t = timeout + (call duration) s
"""
function throttle_ts_old(f, timeout; leading=true, trailing=false)
  tlock = ReentrantLock()
  cooldown = true
  later = nothing
  result = nothing

  function flush(args...; kwargs...)
	lock(tlock)
	try
		later = nothing
		f(args...; kwargs...)
	finally
		unlock(tlock)
	end
  end

  function throttled(args...; kwargs...)
    yield()

    if cooldown
      if leading
		lock(tlock)
		try
        	result = f(args...; kwargs...)
		finally
			unlock(tlock)
		end
      else
        later = () -> f(args...; kwargs...)
      end

      cooldown = false
      @async try
        while (sleep(timeout); later != nothing)
			lock(tlock)
			try
          		later()
				later = nothing
			finally
				unlock(tlock)
		  	end
        end
      finally
        cooldown = true
      end
    elseif trailing
      later = () -> (result = f(args...; kwargs...))
    end

    return result
  end

  return throttled, flush
end

# ╔═╡ Cell order:
# ╠═bf71daae-3d34-11eb-1ca1-d9b018e99f18
# ╠═dde97532-3d34-11eb-030d-054b47086952
# ╠═fac02af2-3d34-11eb-17b8-61505c641f17
# ╠═55752812-3d35-11eb-3962-91f60f0b8219
# ╠═5d2b13be-3d35-11eb-2e47-51223a2a47bf
# ╠═0aec4a64-3d35-11eb-3d3b-a306558f610c
# ╟─880ba494-3b1f-4d1d-95b4-469a7178726c
# ╠═8a1a1300-5f32-445b-8ead-53e700fa186c
# ╠═d97c1432-197f-4fed-8ed9-f2c30612aaca
# ╠═70e27d8e-1d56-48ad-90be-6836d6d68292
# ╠═d18d86d4-bf7a-4819-afe6-a0d24586546b
# ╠═a1c6af58-10d6-45f6-ba0b-b1a45a0d2c56
# ╟─315f67bc-f989-422f-ae60-b6e913c483f6
# ╠═8b59d910-b93e-40c0-bb0d-16cb2a6d3fcc
# ╟─0cdc9124-fb04-441d-bac7-66c83e0c1a7b
# ╠═a2bae643-ad0f-44f1-9e6b-b2ae027c70b0
# ╟─ffbeb451-e5f2-41c5-a499-c3560f07bac4
# ╟─472f989d-8632-4986-bf26-d78a2c7b723a
# ╟─8ecfbbe9-d6f7-4414-afc1-4189abbb0354
# ╠═37611481-6432-4de5-8f37-df85bc9414e8
# ╟─92dee53d-b932-4371-a307-6eece37fc798
# ╠═ae857899-7db3-4bd5-8280-e6128731d234
# ╠═72574513-5cf2-49bf-9a37-e34004501872
# ╟─ffd931d6-be9b-4460-9526-d61bd49b23fc
# ╠═c84a44f0-2422-489e-b16f-d5dc691f3149
# ╠═0cb5ae68-dca4-411a-b13d-71c560f1f1ae
# ╟─0ee72c37-862f-4750-9ff6-ab57f77bad5c
# ╟─9e461a14-0fc9-4d0f-bae3-5b8a1814ee44
# ╟─721c9881-b2c6-4d57-a847-1d08dee6f26c
# ╠═35c23dc6-2c79-4ac1-b085-97d7298c2b97
