report  zfactory.

*----------------------------------------------------------------------*
*- Tipos SAP
*----------------------------------------------------------------------*
type-pools:
  abap, icon .
*----------------------------------------------------------------------*
*- Tabelas
*----------------------------------------------------------------------*
tables:
  snwd_texts .

*----------------------------------------------------------------------*
*- Defini��o da Classe
*----------------------------------------------------------------------*
class minha_classe definition .

  public section .

    types:
      range_node_key type range of snwd_texts-node_key,
      range_parent_key type range of snwd_texts-parent_key .

    methods get_data
      importing
        !node type range_node_key
        !parent type range_parent_key .

    methods show_data .

    class-methods on_added_function
      for event if_salv_events_functions~added_function
             of cl_salv_events_table
      importing e_salv_function.

  protected section .

  private section .

    data:
      out        type table of snwd_texts,
      table      type ref to cl_salv_table,
      selections type ref to cl_salv_selections .

    class-methods process .

    methods config_layout
      changing table type ref to cl_salv_table .

    methods config_column
      changing table type ref to cl_salv_table .


endclass .                    "minha_classe DEFINITION

*----------------------------------------------------------------------*
*- Varaveis Globais
*----------------------------------------------------------------------*
data:
  obj type ref to minha_classe .

*----------------------------------------------------------------------*
*- Implementa��o da Classe
*----------------------------------------------------------------------*
class minha_classe implementation .

  method get_data .

    data:
      lt_where type bvw_tab_where .

    refresh:
      out .

    if lines( node ) eq 0 .
    else .
      append 'NODE_KEY IN NODE' to lt_where .
    endif .

    if lines( parent ) eq 0 .
    else .

      if lines( lt_where ) eq 0 .
        append 'PARENT_KEY IN PARENT' to lt_where .
      else .
        append 'AND PARENT_KEY IN PARENT' to lt_where .
      endif .

    endif .


    if lines( lt_where ) eq 0 .

      select *
        into table out
        from snwd_texts .

    else .

      select *
        into table out
        from snwd_texts
       where (lt_where) .

    endif .

    if sy-subrc eq 0 .
    endif .

    free:
      lt_where .

  endmethod .                    "get_data

  method show_data .

    data:
      display type ref to cl_salv_display_settings,
      sorts   type ref to cl_salv_sorts,
      events  type ref to cl_salv_events_table .

    if out is not initial .

      try.

          call method cl_salv_table=>factory
*           EXPORTING
*             list_display = if_salv_c_bool_sap=>true
            IMPORTING
              r_salv_table = table
            CHANGING
              t_table      = out.

*         Eventos do relat�rio
          events = table->get_event( ).
          set handler minha_classe=>on_added_function for events.

*         Habilita op��o de selecionar linha
          selections = table->get_selections( ).
          selections->set_selection_mode( if_salv_c_selection_mode=>row_column ).

*         Usando Status
          table->set_screen_status(
          pfstatus      = 'STANDARD_FULLSCREEN'
*         report        = 'SAPLKKBL'
          report        = sy-repid
          set_functions = table->c_functions_all ).
*         Obs: � necess�rio criar um bot�o com o c�digo "RUN"
*         no Status GUI que foi copiado do Standard.

*         Configurando Layout
          me->config_layout(
            changing
              table = table
          ) .

*         Configurando Colunas
          me->config_column(
            changing
              table = table
          ) .

*         Layout de Zebra
          display = table->get_display_settings( ) .
          display->set_striped_pattern( cl_salv_display_settings=>true ) .

*        Ordena��o de campos
          sorts = table->get_sorts( ) .
          sorts->add_sort('NODE_KEY') .

          table->display( ).

        catch cx_salv_msg .
        catch cx_salv_not_found .
        catch cx_salv_existing .
        catch cx_salv_data_error .
        catch cx_salv_object_not_found .

      endtry.

    endif .


  endmethod .                    "show_data

  method on_added_function .

    obj->process( ) .

  endmethod .                    "user_command

  method config_layout .

    data:
      layout type ref to cl_salv_layout,
      key    type salv_s_layout_key .

    layout     = table->get_layout( ).
    key-report = sy-repid.
    layout->set_key( key ).
    layout->set_save_restriction( if_salv_c_layout=>restrict_none ).

  endmethod .                    "config_layout

  method config_column .

    data:
      column  type ref to cl_salv_column_list,
      columns type ref to cl_salv_columns_table .

    try .

        columns = table->get_columns( ).
        columns->set_optimize( 'X' ).

        column ?= columns->get_column( 'HIERTYPE' ).
        column->set_technical( if_salv_c_bool_sap=>true ) .

        column ?= columns->get_column( 'NAVTREE' ).
        column->set_icon( if_salv_c_bool_sap=>true ).
        column->set_cell_type( if_salv_c_cell_type=>hotspot ).
        column->set_long_text( 'N�vel' ).
        column->set_symbol( if_salv_c_bool_sap=>true ).

        column ?= columns->get_column( 'GUID' ).
        column->set_technical( if_salv_c_bool_sap=>true ) .

        column ?= columns->get_column( 'SEQNO_OUT' ).
        column->set_technical( if_salv_c_bool_sap=>true ) .

      catch cx_salv_not_found .

    endtry .

  endmethod .                    "config_column

  method process .

    data:
      value type salv_t_row,
      line  type i .

    field-symbols:
      <line> type snwd_texts .

    case sy-ucomm .

      when 'RUN' .

        if obj->table is bound .

          value = obj->selections->get_selected_rows( ) .

          loop at value into line .

            read table obj->out assigning <line> index line .

            if sy-subrc eq 0 .

              concatenate '@S_OKAY@ Processado | '
                          <line>-text
                     into <line>-text
               respecting blanks .

              unassign <line> .

            endif .

          endloop .

          obj->table->refresh( ) .

        endif .

      when others .

    endcase .

  endmethod .                    "link_click

endclass .                    "minha_classe IMPLEMENTATION

*----------------------------------------------------------------------*
*- Tela de sele��o
*----------------------------------------------------------------------*
selection-screen begin of block b1 with frame title text-t01.

select-options:
  node   for snwd_texts-node_key,
  parent for snwd_texts-parent_key .

selection-screen end of block b1.

*----------------------------------------------------------------------*
*- Eventos
*----------------------------------------------------------------------*

initialization .

start-of-selection .

  create object obj .

  obj->get_data(
      node = node[]
      parent = parent[]
   ) .

  obj->show_data( ) .