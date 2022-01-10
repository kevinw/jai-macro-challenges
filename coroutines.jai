//
// My model here are C# generators, which are basically a way of writing a switch statement
// for a state machine without having to store the state value, or write out the switch.
//
// Is this lazy? Yes. Possibly obfuscating the clarity Jai is becoming known for? I'd at
// least like to see the working macro and find out...
//
#import "Compiler";
#import "Program_Print";
#import "Basic";

main :: () {}
#run demo_code_as_graphviz();

// What we'd like to be able to write:
my_code :: #code {
    print("first\n");
    yield();
    print("second\n");
    yield();
    print("done.\n");
};

example_generator :: () {
    generator(my_code);
}

what_the_generated_code_could_look_like :: (state: int) -> int {
    if state == {
        case 0;
            print("first\n");
            return 1;
        case 1;
            print("second\n");
            return 2;
        case 2;
            print("done\n");
            return 3;
    }

    return -1;
}

yield :: () {} // a dummy proc to call for now

demo_code_as_graphviz :: () {
    print("hi from compile time\n");

    sb: String_Builder;

    print_to_builder(*sb, #string END
digraph JaiCodeGraph {
  node [shape=box fontname=Consolas fontsize="9"]
  edge [fontname=Consolas fontsize="8"]
END);

    start_index := 0;
    code_as_graphviz(*sb, compiler_get_nodes(code_of(what_the_generated_code_could_look_like)), *start_index);
    code_as_graphviz(*sb, compiler_get_nodes(code_of(my_code)), *start_index);
    print_to_builder(*sb, "}\n");

    dot_string := builder_to_string(*sb);
    //print("RESULT:\n%\n", dot_string);
    File.write_entire_file("output.dot", dot_string);
    print("OK!\n");
}

generator :: (c: Code) #expand {
    modified :: #run make_generator(c);
    #insert_internal modified;

    make_generator :: (code: Code) -> Code {
        root, expressions := compiler_get_nodes(code);
        for expressions {
            if it.kind != .PROCEDURE_CALL continue;
            proc_call := cast(*Code_Procedure_Call)it;
            if proc_call && proc_call.procedure_expression && proc_call.procedure_expression.kind == .IDENT {
                ident := cast(*Code_Ident)proc_call.procedure_expression;
                if ident && ident.name == "yield" {
                    //print("found a yield\n%\n\n", <<proc_call);
                }
            }
            continue;
        }

        code_if := New_Code_Node(Code_If, .IF);
        //code_if.condition = New_Ident("true");
        code_if.is_switch_statement = true;

        then_block := New_Code_Node(Code_Block, .BLOCK);
        //then_block.parent = code_if;
        then_block.block_type = .IMPERATIVE;

        case_node := New_Code_Node(Code_Case, .CASE);
        case_node.condition = make_string_literal("foobar");

        {
            sb: String_Builder;
            defer free_buffers(*sb);
            print_expression(*sb, root);
            print("CODE:\n%\n", builder_to_string(*sb));
        }

        transformed_code := compiler_get_code(root);
        return transformed_code;
    }
}


New_Code_Node :: ($Node_Type: Type, kind: Code_Node.Kind) -> *Node_Type {
    node := New(Node_Type);
    node.kind = kind;
    return node;
}

New_Ident :: (name: string) -> *Code_Ident {
    ident := New_Code_Node(Code_Ident, .IDENT);
    ident.name = name;
    return ident;
}


#scope_file
File :: #import "File";
#load "./Code_Graphviz.jai";
