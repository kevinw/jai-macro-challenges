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

#run () {
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
    print("RESULT:\n%\n", dot_string);

    File.write_entire_file("output.dot", dot_string);
}();

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

code_as_graphviz :: (sb: *String_Builder, root: *Code_Node, start_index: *int) {

    nodes: [..]*Code_Node;
    array_add(*nodes, root);

    seen_pointers: [..]*void;

    get_node_name :: (ptr: *void) -> (string, bool) #expand {
        found, index := array_find(seen_pointers, ptr);
        wasNew := false;
        if !found {
            index = seen_pointers.count;
            array_add(*seen_pointers, ptr);
            wasNew = true;
        }

        return tprint("Node%", (<<start_index) + index), wasNew;
    }

    add_link :: (sb: *String_Builder, a: *Code_Node, b: *Code_Node, edge_label := "", verbose := false) #expand {
        if !a || !b return;

        //print("add_link(%, %)\n", a, b);
        a_name, a_new := get_node_name(a);
        b_name, b_new := get_node_name(b);
        if b_new {
            array_add_if_unique(*nodes, b);
        }

        label := "";
        if edge_label {
            label = tprint(" [label=\"  %\"]", edge_label);
        }

        print_to_builder(sb, "  % -> % %\n", a_name, b_name, label);
    }

    

    while nodes.count > 0 {
        node := nodes[0];
        print("processing node: %\n", node);
        temp_sb: String_Builder;
        print_expression(*temp_sb, node);
        print("%\n", builder_to_string(*temp_sb));
        nodes.data = nodes.data + 1;
        nodes.count -= 1;

        node_name := get_node_name(node);

        node_filename := get_filename(node);

        if node.kind == {
            case .PROCEDURE_HEADER;
                procedure_header := cast(*Code_Procedure_Header)node;
                print_to_builder(sb, "  % [label=\"Code_Procedure_Header\nname: %\"]\n", node_name, procedure_header.name);
                add_link(sb, procedure_header, procedure_header.body_or_null, "body_or_null");

            case .PROCEDURE_BODY;
                procedure_body := cast(*Code_Procedure_Body)node;
                print_to_builder(sb, "  % [label=\"Code_Procedure_Body\"]\n", node_name);
                add_link(sb, procedure_body, procedure_body.block, "block");

            case .BLOCK;
                block := cast(*Code_Block)node;
                print_to_builder(sb, "  % [label=\"Code_Procedure_Block\"]\n", node_name);
                for block.statements {
                    add_link(sb, block, it, tprint("statements[%]", it_index));
                }

            case .IF;
                code_if := cast(*Code_If)node;
                print_to_builder(sb, "  % [label=\"Code_If\"]\n", node_name);
                add_link(sb, code_if, code_if.condition, "condition");
                add_link(sb, code_if, code_if.then_block, "then");
                add_link(sb, code_if, code_if.else_block, "else");
            
            case .RETURN;
                print_to_builder(sb, "  % [label=\"Code_Return\"]\n", node_name);
                code_return := cast(*Code_Return)node;
                for code_return.arguments_unsorted {
                    edge_name := ifx it.name then it.name.name else "";
                    add_link(sb, code_return, it.expression, edge_name);
                }
            
            case .IDENT;
                ident := cast(*Code_Ident)node;
                print_to_builder(sb, "  % [label=\"Code_Ident\nname: %\"]\n", node_name, ident.name);
            
            case .LITERAL;
                literal := cast(*Code_Literal)node;

                value_sb: String_Builder;
                print_expression(*value_sb, literal);

                print_to_builder(sb, "  % [label=\"Code_Literal\nvalue_type: .%\n\n%\"]\n", node_name, literal.value_type, builder_to_string(*value_sb));
            
            case .CASE;
                code_case := cast(*Code_Case)node;
                print_to_builder(sb, "  % [label=\"Code_Case\"]\n", node_name);
                add_link(sb, code_case, code_case.condition, "condition");
                add_link(sb, code_case, code_case.then_block, "then_block");
            
            case .PROCEDURE_CALL;
                procedure_call := cast(*Code_Procedure_Call)node;
                print_to_builder(sb, "  % [label=\"Code_Procedure_Call\"]\n", node_name);
                add_link(sb, procedure_call, procedure_call.procedure_expression, "procedure_expression");
            
            case .DIRECTIVE_CODE;
                code_directive_code := cast(*Code_Directive_Code)node;
                print_to_builder(sb, "  % [label=\"Code_Directive_Code\"]\n", node_name);
                add_link(sb, code_directive_code, code_directive_code.expression, "expression");

            case;
                print_to_builder(sb, "  % [label=\"Unknown .%\"]\n", node_name, node.kind);

        }
    }


/*
digraph D {

  A [shape=diamond]
  B [shape=box]
  C [shape=circle]

  A -> B [style=dashed, color=grey]
  A -> C [color="black:invis:black"]
  A -> D [penwidth=5, arrowhead=none]
}
*/

    <<start_index += seen_pointers.count;
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
                    //print("found a yield\n%\n\n", <<proc_call);
                }
            }
            continue;
        }

        //print_code_nodes(root);
        
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

#scope_file
File :: #import "File";
