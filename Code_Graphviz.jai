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

    add_link :: (a: *Code_Node, b: *Code_Node, edge_label := "", verbose := false) #expand {
        if !a || !b return;
        a_name, a_new := get_node_name(a);
        b_name, b_new := get_node_name(b);
        if b_new array_add_if_unique(*nodes, b);

        label := ifx edge_label tprint(" [label=\"  %\"]", edge_label) else "";
        print_to_builder(sb, "  % -> % %\n", a_name, b_name, label);
    }

    while nodes.count > 0 {
        node := nodes[0];
        temp_sb: String_Builder;
        print_expression(*temp_sb, node);
        print("%\n", builder_to_string(*temp_sb));
        nodes.data = nodes.data + 1;
        nodes.count -= 1;

        node_name := get_node_name(node);

        node_filename := get_filename(node);

        p :: (label: string, args: .. Any) #expand {
            label_string := tprint(label, ..args);
            print_to_builder(sb, "  % [label=\"%\"]", node_name, label_string);
        }

        if node.kind == {
            case .PROCEDURE_HEADER;
                using procedure_header := cast(*Code_Procedure_Header)node;
                p("Code_Procedure_Header\nname: %", name);
                add_link(procedure_header, body_or_null, "body_or_null");

            case .PROCEDURE_BODY;
                using procedure_body := cast(*Code_Procedure_Body)node;
                p("Code_Procedure_Body");
                add_link(procedure_body, block, "block");

            case .BLOCK;
                using block := cast(*Code_Block)node;
                p("Code_Procedure_Block");
                for statements {
                    add_link(block, it, tprint("statements[%]", it_index));
                }

            case .IF;
                using code_if := cast(*Code_If)node;
                p("Code_If");
                add_link(code_if, condition, "condition");
                add_link(code_if, then_block, "then");
                add_link(code_if, else_block, "else");
            
            case .RETURN;
                using code_return := cast(*Code_Return)node;
                p("Code_Return");
                for arguments_unsorted {
                    edge_name := ifx it.name then it.name.name else "";
                    add_link(code_return, it.expression, edge_name);
                }
            
            case .IDENT;
                using ident := cast(*Code_Ident)node;
                p("Code_Ident\nname: %", name);
            
            case .LITERAL;
                using literal := cast(*Code_Literal)node;

                value_sb: String_Builder;
                print_expression(*value_sb, literal);

                p("Code_Literal\nvalue_type: .%\n\n%", value_type, builder_to_string(*value_sb));
            
            case .CASE;
                using code_case := cast(*Code_Case)node;
                p("Code_Case");
                add_link(code_case, condition, "condition");
                add_link(code_case, then_block, "then_block");
            
            case .PROCEDURE_CALL;
                using procedure_call := cast(*Code_Procedure_Call)node;
                p("Code_Procedure_Call");
                add_link(procedure_call, procedure_expression, "procedure_expression");
            
            case .DIRECTIVE_CODE;
                using code_directive_code := cast(*Code_Directive_Code)node;
                p("Code_Directive_Code");
                add_link(code_directive_code, expression, "expression");

            case;
                p("Unknown .%", node.kind);

        }
    }

    <<start_index += seen_pointers.count;
}

#scope_file
#import "Basic";
#import "Compiler";