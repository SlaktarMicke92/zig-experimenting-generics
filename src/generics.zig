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

const Poison = struct {
    value: i16,
    applied_to: *Stats,

    pub fn apply(self: Poison) void {
        self.applied_to.subtract(self.value);
    }
};

const Rejuvenation = struct {
    value: i16,
    applied_to: *Stats,

    pub fn apply(self: Rejuvenation) void {
        self.applied_to.add(self.value);
    }
};

fn StatusEffect(comptime T: type, comptime time_between_ticks: f32, comptime ticks: u8) type {
    return struct {
        effect: T,
        timer: f32 = 0,
        time_between_ticks: f32 = time_between_ticks,
        ticks: u8 = ticks,

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
                self.effect.apply();
            }
        }
    };
}

const PoisonEffect = StatusEffect(Poison, 0.5, 3);
const RejuvenationEffect = StatusEffect(Rejuvenation, 0.1, 1);

test "generics" {
    const delta_time: f32 = 0.1667;
    var stats = Stats{};
    var poison_effect = PoisonEffect{ .effect = Poison{ .value = 2, .applied_to = &stats } };
    var rejuvenation_effect = RejuvenationEffect{ .effect = Rejuvenation{ .value = 5, .applied_to = &stats } };
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
