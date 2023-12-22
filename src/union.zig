const expect = @import("std").testing.expect;

pub const Stats = struct {
    health: i16 = 10,

    const Self = @This();

    pub fn add(self: *Self, amount: i16) void {
        self.health += amount;
    }

    pub fn subtract(self: *Self, amount: i16) void {
        self.health -= amount;
    }
};

const Effect = union(enum) {
    poison: Poison,
    rejuvenation: Rejuvenation,

    const Self = @This();

    pub inline fn apply(self: Self, stats: *Stats) void {
        switch (self) {
            inline else => |effect| effect.apply(stats),
        }
    }
};

const StatusEffect = struct {
    timer: f32 = 0,
    time_between_ticks: f32,
    ticks: u8,
    effect: Effect,
    applied_to: *Stats,

    const Self = @This();

    pub fn deinit(self: *Self) void {
        self.effect = undefined;
        self.* = undefined;
    }

    pub fn update_timer(self: *Self, delta_time: *const f32) void {
        self.timer += delta_time.*;
    }

    pub fn apply_effect(self: *Self) void {
        if (self.timer >= self.time_between_ticks and self.ticks > 0) {
            self.timer = 0;
            self.ticks -= 1;
            self.effect.apply(self.applied_to);
        }
    }
};

const Poison = struct {
    value: i16,

    pub fn apply(self: Poison, stats: *Stats) void {
        stats.subtract(self.value);
    }
};

const Rejuvenation = struct {
    value: i16,

    pub fn apply(self: Rejuvenation, stats: *Stats) void {
        stats.add(self.value);
    }
};

test "union" {
    const delta_time: f32 = 0.1667;
    var stats = Stats{};
    var poison_effect = StatusEffect{
        .effect = Effect{ .poison = Poison{ .value = 2 } },
        .applied_to = &stats,
        .ticks = 3,
        .time_between_ticks = 0.5,
    };
    var rejuvenation_effect = StatusEffect{
        .effect = Effect{ .rejuvenation = Rejuvenation{ .value = 5 } },
        .applied_to = &stats,
        .ticks = 1,
        .time_between_ticks = 0.1,
    };
    defer poison_effect.deinit();
    defer rejuvenation_effect.deinit();

    poison_effect.update_timer(&delta_time);
    poison_effect.update_timer(&delta_time);
    poison_effect.apply_effect();
    try expect(0 != poison_effect.timer);
    // At this point the timer has not gone past tick time
    poison_effect.update_timer(&delta_time);
    poison_effect.apply_effect();
    try expect(stats.health == 8);

    rejuvenation_effect.update_timer(&delta_time);
    rejuvenation_effect.apply_effect();
    try expect(stats.health == 13);
}
