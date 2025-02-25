const std = @import("std");
const rand = std.rand;
const rl = @import("raylib");
const rlm = rl.math;
const Vector2 = rl.Vector2;

const sounds = @import("sound.zig").sounds;
const Game = @import("game.zig").Game;
const Asteroid = @import("asteroid.zig").Asteroid;
const Ship = @import("ship.zig").Ship;
const Alien = @import("alien.zig").Alien;

fn isPosInMap(pos: Vector2, bounds: Game.Bounds) bool {
    if (pos.x < bounds.left_bound or pos.x > bounds.right_bound or
        pos.y < bounds.top_bound or pos.y > bounds.bottom_bound)
    {
        return false;
    }

    return true;
}

pub const Projectile = struct {
    pub const max_projectiles = 5;
    const projectile_speed = 4.0;

    pos: Vector2,
    angle: f32,

    pub fn new(pos: Vector2, angle: f32) Projectile {
        var projectile: Projectile = .{
            .pos = pos,
            .angle = angle,
        };

        projectile.pos.x += @cos(angle) * Ship.collision_radius;
        projectile.pos.y += @sin(angle) * Ship.collision_radius;

        return projectile;
    }

    /// If returned true, the projectile is to be destroyed
    pub fn update(
        self: *Projectile,
        bounds: Game.Bounds,
        ship: *Ship,
        asteroids: *std.ArrayList(Asteroid),
        aliens: []Alien,
        prng: *rand.DefaultPrng,
    ) !bool {
        self.pos.x += projectile_speed * @cos(self.angle) * Game.deltaTimeNormalized();
        self.pos.y += projectile_speed * @sin(self.angle) * Game.deltaTimeNormalized();

        if (!isPosInMap(self.pos, bounds)) {
            return true;
        }

        if (rlm.vector2Distance(self.pos, ship.pos) < Ship.collision_radius) {
            ship.hasCollided(prng);
            return true;
        }

        for (aliens) |*alien| {
            if (rlm.vector2Distance(self.pos, alien.pos) <= Alien.collision_radius) {
                alien.takeHit();
            }
        }

        for (asteroids.items) |*astr| {
            if (rlm.vector2Distance(astr.pos, self.pos) <= Asteroid.radius(astr.size)) {
                astr.hit_by_projectile = true;
                return true;
            }
        }

        return false;
    }
};
