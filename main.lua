function love.load()
	move = love.graphics.newComputeShader([[
		struct Particle {
			vec2 position;
			vec2 velocity;
			uint kind;
		};

		buffer Particles {
			Particle particles[];
		};

		uniform float dt;
		uniform uint count;

		layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;
		void computemain() {
			uint index = love_GlobalThreadID.x;

			if (index >= count) {
				return;
			}

			particles[index].position += particles[index].velocity * dt;

			vec2 position = particles[index].position;
			if (position.x < 0.) particles[index].position.x += 10240.;
			if (position.x > 10240.) particles[index].position.x -= 10240.;
			if (position.y < 0.) particles[index].position.y += 5760.;
			if (position.y > 5760.) particles[index].position.y -= 5760.;
		}
	]])

	force = love.graphics.newComputeShader([[
		struct Particle {
			vec2 position;
			vec2 velocity;
			uint kind;
		};

		buffer Particles {
			Particle particles[];
		};

		uniform float dt;
		uniform float frictionFactor;
		uniform uint count;

		uniform float attractionmatrix[49];

		float calculateforce(float r, float a) {
			float beta = 0.3f;

			if (r < beta) {
				return r / beta - 1.;
			} else if (beta < r && r < 1.) {
				return a * (1. - abs(2. * r - 1. - beta) / (1. - beta)); 
			} else {
				return 0.;
			}
		}

		layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;
		void computemain() {
			uint index = love_GlobalThreadID.x;

			if (index >= count) {
				return;
			}

			vec2 force;

			for (uint o_index; o_index < count; o_index++) {
				Particle o_particle = particles[o_index];

				vec2 delta = o_particle.position - particles[index].position;
				delta.x = delta.x - 1. * floor((delta.x + 10240. / 2.) / 10240.);
				delta.y = delta.y - 1. * floor((delta.y + 5760. / 2.) / 5760.);

				float distance = sqrt(delta.x * delta.x + delta.y * delta.y);

				if (distance > 0. && distance < 200.) {
					float a = attractionmatrix[particles[index].kind + o_particle.kind * 3];
					float f = calculateforce(distance / 200., a);

					force += delta / distance * f;
				}
			}

			force *= 200. * 10.;

			particles[index].velocity *= frictionFactor;
			particles[index].velocity += force * dt;
		}
	]])

	renderer = love.graphics.newShader([[
		#pragma language glsl4

		struct Particle {
			vec2 position;
			vec2 velocity;
			uint kind;
		};

		readonly buffer Particles {
			Particle particles[];
		};

		#ifdef VERTEX
			vec4 colorbytes(float r, float g, float b) {
				return vec4(r / 255., g / 255., b / 255., 1.);
			}

			vec4 colors[] = {
				colorbytes(234, 89, 89),
				colorbytes(234, 168, 86),
				colorbytes(239, 215, 127),
				colorbytes(143, 217, 86),
				colorbytes(99, 216, 162),
				colorbytes(99, 216, 162),
				colorbytes(99, 216, 162),
				colorbytes(99, 216, 162),
				colorbytes(73, 142, 188),
				colorbytes(106, 85, 209)
			};

			out vec4 vColor;
			
			vec4 position(mat4 transform_projection, vec4 vertex_position) {
				gl_PointSize = 1;
				uint index = love_VertexID;
				vColor = colors[particles[index].kind];
				return transform_projection * vec4(particles[index].position, 0., 1.);
			}
		#endif

		#ifdef PIXEL
			in vec4 vColor;
			vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
				return vColor;
			}
		#endif
	]])

	format = {
		{ name = "position", format = "floatvec2" },
		{ name = "velocity", format = "floatvec2" },
		{ name = "kind", format = "uint32" },
	}

	count = 20000
	particles = love.graphics.newBuffer(format, count, { shaderstorage = true })

	move:send("Particles", particles)
	move:send("count", count)

	force:send("Particles", particles)
	force:send("count", count)

	renderer:send("Particles", particles)

	local data = {}
	local width, height = love.graphics.getDimensions()
	local r, rn = love.math.random, love.math.randomNormal
	for i = 1, count do
		table.insert(data, {
			r(width * 8), r(height * 8),
			rn(100), rn(100),
			r() * 10
		})
	end

	particles:setArrayData(data)

	local attractionmatrix = {}
	for i = 1, 7 * 7 do
		attractionmatrix[i] = love.math.random() * 2 - 1;
	end
	force:send("attractionmatrix", unpack(attractionmatrix))

	mesh = love.graphics.newMesh({
		{ name = "VertexPosition", format = "float"}
	}, count, "points")
end

local running = true

function love.update(dt)
	dt = math.min(dt, 1 / 60)

	move:send("dt", dt)

	local frictionHalfLife = 0.04
	local frictionFactor = math.pow(0.5, dt / frictionHalfLife)

	force:send("dt", dt)
	force:send("frictionFactor", frictionFactor)

	if (running) then
		local groupCount = math.ceil(count / move:getLocalThreadgroupSize())
		love.graphics.dispatchThreadgroups(force, groupCount)
		love.graphics.dispatchThreadgroups(move, groupCount)
	end
end

function love.draw()
	love.graphics.setShader(renderer)
	love.graphics.scale(0.125, 0.125)
	love.graphics.draw(mesh)
	love.graphics.setShader()

	love.window.setTitle(love.timer.getFPS())
end

function love.keypressed(key)
	if (key == "space") then
		running = not running
	end
end
