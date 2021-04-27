/*

// What we'd like to be able to write:

main :: () {
    seen_the_number_six := false;
    all_values: [..]int;

    func_taking_a_callback(.[1, 2, 3, 4, 5, 6, 7, 8, 101, 102, 103], closure(#code {
        array_add(*all_values, in_value);
        seen_the_number_six |= in_value == 6;
    }));
}

*/

main :: () {
    // What it would "desugar" into after macro expansion:

    seen_the_number_six := false;
    all_values: [..]int;

    // GENERATED
    Closure_Context :: struct {
        seen_the_number_six: *bool;
        all_values: *[..]int;
    }
    ctx: Closure_Context;
    ctx.seen_the_number_six = *seen_the_number_six;
    ctx.all_values = *all_values;

    func_taking_a_callback(.[1, 2, 3, 4, 5, 6, 7, 8, 101, 102, 103], xx my_closure, *ctx);
    my_closure :: (in_value: int, ctx: *Closure_Context) {
        using ctx;
        array_add(all_values, in_value);
        (<<seen_the_number_six) |= (in_value == 6);
    }

    print("seen_the_number_six: %\nall_values: %\n", seen_the_number_six, all_values);
}

func_taking_a_callback :: (elems: []int, func: #type (int, user_data: *void), user_data: *void) {
    for elems
        if it % 2 == 0
            func(it, user_data);
}

#scope_file
#import "Basic";
