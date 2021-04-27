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

func_taking_a_callback :: (elems: []int, func: #type (int, user_data: *void), user_data: *void) {
    for elems
        if it % 2 == 0
            func(it, user_data);
}

main :: () {
    Closure_Context :: struct {
        seen_the_number_six := false;
        all_values: [..]int;
    }
    ctx: Closure_Context;

    func_taking_a_callback(.[1, 2, 3, 4, 5, 6, 7, 8, 101, 102, 103], xx my_closure, *ctx);

    my_closure :: (in_value: int, ctx: *Closure_Context) {
        using ctx;
        array_add(*all_values, in_value);
        seen_the_number_six |= (in_value == 6);
    }

    enable_long_form_struct_printing();
    print("%", ctx);
}

#scope_file
enable_long_form_struct_printing :: () {
    using context.print_style.default_format_struct;
    use_long_form_if_more_than_this_many_members = -1;
    draw_type_name = true;
    use_newlines_if_long_form = true;
}
#import "Basic";
