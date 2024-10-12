const std = @import("std");

pub fn main() !void {
    // Generating seed.
    // I declare the variable as undefined so that later I can asign a random 64 bit unsigned integer given to me by the OS.
    // Not exactly sure how this works, but this is my understanding as of right now:
    // The std.mem.asBytes function takes in a pointer to my seed and changes it from undefined to a byte representation.
    // That function must return the same pointer, since the next function in line, std.posix.getrandom, changes my seed in-place.
    // I believe that std.posix.getrandom retrieves a random number generated in the kernel and assigns it to the seed variable.
    var seed: u64 = undefined;
    try std.posix.getrandom(std.mem.asBytes(&seed));

    // Here I am getting a RNG. I don't completely understand how the internals work, nor what are the types of the variables I am working with.
    // On a high level, I am setting a seed and then getting a RNG that I can store in const rand. That is all I know. I don't know what prng variable holds,
    // nor do I know what Prng is. I also don't know the type of const rand.
    //
    // This is sorcery to me!
    var prng = std.Random.DefaultPrng.init(seed);
    const rand = prng.random();

    // This is pretty straight forward. I am generating a random u8 from 1 to 100.
    const num: u8 = rand.intRangeAtMost(u8, 1, 100);

    // Here I am declaring the stdout and stdin constants that I can later use to work with standard I/O. I know how they work on a high level, but
    // I don't know what types those are and how would I specify them if I, for instance, wanted to pass them down to a function or something.
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    // This is basically a print that does not require a tuple. Useful for when I don't need any formatting. Not sure if there is something else to it.
    try stdout.writeAll("I just thought of a random number between 1 and 100, can you guess it?\n");

    // Here is the main loop. I will keep asking the user for an input until they get the number right.
    while (true) {
        // I am new to heap allocators, so this is hard for me to understand. On a high level I know that I am reading the stdin until I can find a '\n'
        // character (until the user presses enter). Whatever I've collected goes to the heap, since this functions appears to be using the page_allocator under
        // the hood. I don't know how it works, but I also can guess that the number of bytes being allocated is 8192. Or maybe they are bits, who knows? Eitherway,
        // I think that is too big of a buffer, but still I'm leaving it as is because it works.
        const bare_line = try stdin.readUntilDelimiterAlloc(
            std.heap.page_allocator,
            '\n',
            8192,
        );

        // I free any memory used to hold the bare_line constant upon exiting the main function scope.
        defer std.heap.page_allocator.free(bare_line);

        // ??? I guess this removes the '\r' character from either side of the string? Like .strip('\r') in Python? Idk, I'm a soy dev.
        //
        // What even is the '\r' and how would it end up in the input?
        const line = std.mem.trim(u8, bare_line, "\r");

        // std.fmt.parseInt helps me to parse the line to a u8 int in base 10, I believe.
        // If there are any errors, I handle them using the switch statement.
        const guess = std.fmt.parseInt(u8, line, 10) catch |err| switch (err) {
            error.Overflow => {
                try stdout.writeAll("Please enter a small positive number\n");
                continue;
            },
            error.InvalidCharacter => {
                try stdout.writeAll("Please enter a valid number\n");
                continue;
            },
        };

        // Once the guess is the same type as the num, I can finally compare them. This does not need explaination (not for me at least).
        if (guess < num) try stdout.writeAll("Too small\n");
        if (guess > num) try stdout.writeAll("Too big\n");
        if (guess == num) {
            try stdout.print("Correct! The random number was: {}\n", .{num});
            break;
        }
    }
}
