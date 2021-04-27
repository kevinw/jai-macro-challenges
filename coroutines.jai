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

// What we'd like to be able to write:

example_generator :: () {
    generator(#code {
        print("first\n");
        yield();
        print("second\n");
        yield();
        print("done.\n");
    });
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
                    print("found a yield\n%\n\n", <<proc_call);
                }
            }
            continue;
        }

        print_code_nodes(root);
        
        code_if := New_Code_Node(Code_If, .IF);
        //code_if.condition = New_Ident("true");
        code_if.is_switch_statement = true;

        then_block := New_Code_Node(Code_Block, .BLOCK);
        //then_block.parent = code_if;
        then_block.block_type = .IMPERATIVE;

        case_node := New_Code_Node(Code_Case, .CASE);
        case_node.condition = make_string_literal("foobar");

        /*
        this is incomplete.
        i wonder if a simple library for assembling codes is in order...
        */

        assert(root.kind == .BLOCK);
        root_block := cast(*Code_Block)root;
        code_if.then_block = root_block;
        case_node.then_block = root_block;
        case_node.owning_if = code_if;

        statements: [..]*Code_Node;
        (<<array_add(*statements)) = case_node;

        then_block.statements = statements;


        root = code_if;
        */

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

main :: () {
}


print_code_nodes :: (code_node: *Code_Node, indent := 0) {
    if code_node == null {
        print("null\n");
        return;
    }

    s: string;
    s.count = indent * 4;
    s.data = talloc(s.count);

    if code_node.kind == {
        case .BLOCK;
            using block_node := cast(*Code_Block)code_node;
            print("%\n", <<block_node);
            print("members:\n");
            for members print_code_nodes(it, indent + 1);
            print("statements:\n");
            for statements print_code_nodes(it, indent + 1);
        case .PROCEDURE_CALL;
            using proc_call := cast(*Code_Procedure_Call)code_node;
            print("%\n", <<proc_call);
            print("  procedure_expression:\n");
            print_code_nodes(procedure_expression, indent + 1);
            print("  arguments_sorted:\n");
            for arguments_sorted print_code_nodes(it, indent + 1);
        case .IDENT;
            using ident := cast(*Code_Ident)code_node;
            print("%\n", <<ident);

        case;
            print("unhandled code node %\n", code_node.kind);
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
