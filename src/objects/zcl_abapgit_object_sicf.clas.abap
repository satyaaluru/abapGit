CLASS zcl_abapgit_object_sicf DEFINITION
  PUBLIC
  INHERITING FROM zcl_abapgit_objects_super
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES zif_abapgit_object .

    ALIASES mo_files
      FOR zif_abapgit_object~mo_files .

    CLASS-METHODS read_tadir_sicf
      IMPORTING
        !iv_pgmid       TYPE tadir-pgmid DEFAULT 'R3TR'
        !iv_obj_name    TYPE tadir-obj_name
      RETURNING
        VALUE(rs_tadir) TYPE tadir
      RAISING
        zcx_abapgit_exception .
    CLASS-METHODS read_sicf_url
      IMPORTING
        !iv_obj_name   TYPE tadir-obj_name
      RETURNING
        VALUE(rv_hash) TYPE text25
      RAISING
        zcx_abapgit_exception .
  PRIVATE SECTION.

    TYPES:
      ty_icfhandler_tt TYPE STANDARD TABLE OF icfhandler WITH DEFAULT KEY .
    TYPES:
      BEGIN OF ty_sicf_key,
        icf_name   TYPE icfservice-icf_name,
        icfparguid TYPE icfservice-icfparguid,
      END OF ty_sicf_key .

    METHODS read
      IMPORTING
        !iv_clear      TYPE abap_bool DEFAULT abap_true
      EXPORTING
        !es_icfservice TYPE icfservice
        !es_icfdocu    TYPE icfdocu
        !et_icfhandler TYPE ty_icfhandler_tt
        !ev_url        TYPE string
      RAISING
        zcx_abapgit_exception .
    METHODS insert_sicf
      IMPORTING
        !is_icfservice TYPE icfservice
        !is_icfdocu    TYPE icfdocu
        !it_icfhandler TYPE ty_icfhandler_tt
        !iv_package    TYPE devclass
        !iv_url        TYPE string
      RAISING
        zcx_abapgit_exception .
    METHODS change_sicf
      IMPORTING
        !is_icfservice TYPE icfservice
        !is_icfdocu    TYPE icfdocu
        !it_icfhandler TYPE ty_icfhandler_tt
        !iv_package    TYPE devclass
        !iv_parent     TYPE icfparguid
      RAISING
        zcx_abapgit_exception .
    METHODS to_icfhndlist
      IMPORTING
        !it_list       TYPE ty_icfhandler_tt
      RETURNING
        VALUE(rt_list) TYPE icfhndlist .
    METHODS find_parent
      IMPORTING
        !iv_url          TYPE string
      RETURNING
        VALUE(rv_parent) TYPE icfparguid
      RAISING
        zcx_abapgit_exception .
ENDCLASS.



CLASS ZCL_ABAPGIT_OBJECT_SICF IMPLEMENTATION.


  METHOD change_sicf.

    DATA: lt_icfhndlist TYPE icfhndlist,
          lt_existing   TYPE TABLE OF icfhandler,
          ls_icfserdesc TYPE icfserdesc.

    FIELD-SYMBOLS: <ls_existing> LIKE LINE OF lt_existing.


    lt_icfhndlist = to_icfhndlist( it_icfhandler ).

* Do not add handlers if they already exist, it will make the below
* call to SAP standard code raise an exception
    SELECT * FROM icfhandler INTO TABLE lt_existing
      WHERE icf_name = is_icfservice-icf_name.
    LOOP AT lt_existing ASSIGNING <ls_existing>.
      DELETE TABLE lt_icfhndlist FROM <ls_existing>-icfhandler.
    ENDLOOP.

    MOVE-CORRESPONDING is_icfservice TO ls_icfserdesc.

    cl_icf_tree=>if_icf_tree~change_node(
      EXPORTING
        icf_name                  = is_icfservice-orig_name
        icfparguid                = iv_parent
        icfdocu                   = is_icfdocu
        doculang                  = mv_language
        icfhandlst                = lt_icfhndlist
        package                   = iv_package
        application               = space
        icfserdesc                = ls_icfserdesc
        icfactive                 = abap_true
      EXCEPTIONS
        empty_icf_name            = 1
        no_new_virtual_host       = 2
        special_service_error     = 3
        parent_not_existing       = 4
        enqueue_error             = 5
        node_already_existing     = 6
        empty_docu                = 7
        doculang_not_installed    = 8
        security_info_error       = 9
        user_password_error       = 10
        password_encryption_error = 11
        invalid_url               = 12
        invalid_otr_concept       = 13
        formflg401_error          = 14
        handler_error             = 15
        transport_error           = 16
        tadir_error               = 17
        package_not_found         = 18
        wrong_application         = 19
        not_allow_application     = 20
        no_application            = 21
        invalid_icfparguid        = 22
        alt_name_invalid          = 23
        alternate_name_exist      = 24
        wrong_icf_name            = 25
        no_authority              = 26
        OTHERS                    = 27 ).
    IF sy-subrc <> 0.
      zcx_abapgit_exception=>raise( 'SICF - error from change_node' ).
    ENDIF.

  ENDMETHOD.                    "change_sicf


  METHOD find_parent.

    cl_icf_tree=>if_icf_tree~service_from_url(
      EXPORTING
        url                   = iv_url
        hostnumber            = 0
      IMPORTING
        icfnodguid            = rv_parent
      EXCEPTIONS
        wrong_application     = 1
        no_application        = 2
        not_allow_application = 3
        wrong_url             = 4
        no_authority          = 5
        OTHERS                = 6 ).
    IF sy-subrc <> 0.
      zcx_abapgit_exception=>raise( 'SICF - error from service_from_url' ).
    ENDIF.

  ENDMETHOD.                    "find_parent


  METHOD insert_sicf.

    DATA: lt_icfhndlist TYPE icfhndlist,
          ls_icfserdesc TYPE icfserdesc,
          ls_icfdocu    TYPE icfdocu,
          lv_parent     TYPE icfparguid.


    lt_icfhndlist = to_icfhndlist( it_icfhandler ).
    lv_parent = find_parent( iv_url ).

* nice, it seems that the structure should be mistreated
    ls_icfdocu = is_icfdocu-icf_docu.

    MOVE-CORRESPONDING is_icfservice TO ls_icfserdesc.

    cl_icf_tree=>if_icf_tree~insert_node(
      EXPORTING
        icf_name                  = is_icfservice-orig_name
        icfparguid                = lv_parent
        icfdocu                   = ls_icfdocu
        doculang                  = mv_language
        icfhandlst                = lt_icfhndlist
        package                   = iv_package
        application               = space
        icfserdesc                = ls_icfserdesc
        icfactive                 = abap_true
      EXCEPTIONS
        empty_icf_name            = 1
        no_new_virtual_host       = 2
        special_service_error     = 3
        parent_not_existing       = 4
        enqueue_error             = 5
        node_already_existing     = 6
        empty_docu                = 7
        doculang_not_installed    = 8
        security_info_error       = 9
        user_password_error       = 10
        password_encryption_error = 11
        invalid_url               = 12
        invalid_otr_concept       = 13
        formflg401_error          = 14
        handler_error             = 15
        transport_error           = 16
        tadir_error               = 17
        package_not_found         = 18
        wrong_application         = 19
        not_allow_application     = 20
        no_application            = 21
        invalid_icfparguid        = 22
        alt_name_invalid          = 23
        alternate_name_exist      = 24
        wrong_icf_name            = 25
        no_authority              = 26
        OTHERS                    = 27 ).
    IF sy-subrc <> 0.
      zcx_abapgit_exception=>raise( |SICF - error from insert_node: { sy-subrc }| ).
    ENDIF.

  ENDMETHOD.                    "insert_sicf


  METHOD read.

    DATA: lt_serv_info TYPE icfservtbl,
          ls_serv_info LIKE LINE OF lt_serv_info,
          ls_key       TYPE ty_sicf_key.

    FIELD-SYMBOLS: <ls_icfhandler> LIKE LINE OF et_icfhandler.


    CLEAR es_icfservice.
    CLEAR es_icfdocu.
    CLEAR et_icfhandler.
    CLEAR ev_url.

    ls_key = read_tadir_sicf( ms_item-obj_name )-obj_name.

    cl_icf_tree=>if_icf_tree~get_info_from_serv(
      EXPORTING
        icf_name          = ls_key-icf_name
        icfparguid        = ls_key-icfparguid
        icf_langu         = mv_language
      IMPORTING
        serv_info         = lt_serv_info
        icfdocu           = es_icfdocu
        url               = ev_url
      EXCEPTIONS
        wrong_name        = 1
        wrong_parguid     = 2
        incorrect_service = 3
        no_authority      = 4
        OTHERS            = 5 ).
    IF sy-subrc <> 0.
      zcx_abapgit_exception=>raise( 'SICF - error from get_info_from_serv' ).
    ENDIF.

    ASSERT lines( lt_serv_info ) = 1.
    READ TABLE lt_serv_info INDEX 1 INTO ls_serv_info.
    ASSERT sy-subrc = 0.

    MOVE-CORRESPONDING ls_serv_info-service TO es_icfservice.
    IF iv_clear = abap_true.
      CLEAR es_icfservice-icf_cuser.
      CLEAR es_icfservice-icf_cdate.
      CLEAR es_icfservice-icf_muser.
      CLEAR es_icfservice-icf_mdate.
    ENDIF.

    CLEAR es_icfdocu-icfparguid.

    APPEND LINES OF ls_serv_info-handlertbl TO et_icfhandler.
    LOOP AT et_icfhandler ASSIGNING <ls_icfhandler>.
      CLEAR <ls_icfhandler>-icfparguid.
    ENDLOOP.

  ENDMETHOD.                    "read


  METHOD read_sicf_url.

    DATA: lv_name    TYPE icfname,
          lv_url     TYPE string,
          lv_parguid TYPE icfparguid.


    lv_name    = iv_obj_name.
    lv_parguid = iv_obj_name+15.

    cl_icf_tree=>if_icf_tree~get_info_from_serv(
      EXPORTING
        icf_name          = lv_name
        icfparguid        = lv_parguid
      IMPORTING
        url               = lv_url
      EXCEPTIONS
        wrong_name        = 1
        wrong_parguid     = 2
        incorrect_service = 3
        no_authority      = 4
        OTHERS            = 5 ).
    IF sy-subrc = 0.
      rv_hash = zcl_abapgit_hash=>sha1_raw( zcl_abapgit_convert=>string_to_xstring_utf8( lv_url ) ).
    ENDIF.

  ENDMETHOD.


  METHOD read_tadir_sicf.

    DATA: lt_tadir    TYPE STANDARD TABLE OF tadir WITH DEFAULT KEY,
          lv_hash     TYPE text25,
          lv_obj_name TYPE tadir-obj_name.

    FIELD-SYMBOLS: <ls_tadir> LIKE LINE OF lt_tadir.


    lv_hash = iv_obj_name+15.
    CONCATENATE iv_obj_name(15) '%' INTO lv_obj_name.

    SELECT * FROM tadir INTO TABLE lt_tadir
      WHERE pgmid = iv_pgmid
      AND object = 'SICF'
      AND obj_name LIKE lv_obj_name
      ORDER BY PRIMARY KEY.

    LOOP AT lt_tadir ASSIGNING <ls_tadir>.
      IF read_sicf_url( <ls_tadir>-obj_name ) = lv_hash.
        rs_tadir = <ls_tadir>.
        RETURN.
      ENDIF.
    ENDLOOP.

    IF lines( lt_tadir ) = 1.
      READ TABLE lt_tadir INDEX 1 ASSIGNING <ls_tadir>.
      ASSERT sy-subrc = 0.
      rs_tadir = <ls_tadir>.
    ENDIF.

  ENDMETHOD.


  METHOD to_icfhndlist.

    FIELD-SYMBOLS: <ls_list> LIKE LINE OF it_list.


* convert to sorted table
    LOOP AT it_list ASSIGNING <ls_list>.
      INSERT <ls_list>-icfhandler INTO TABLE rt_list.
    ENDLOOP.

  ENDMETHOD.                    "to_icfhndlist


  METHOD zif_abapgit_object~changed_by.

    DATA: ls_icfservice TYPE icfservice.


    read( EXPORTING iv_clear = abap_false
          IMPORTING es_icfservice = ls_icfservice ).

    rv_user = ls_icfservice-icf_muser.

    IF rv_user IS INITIAL.
      rv_user = c_user_unknown.
    ENDIF.

  ENDMETHOD.


  METHOD zif_abapgit_object~compare_to_remote_version.
    CREATE OBJECT ro_comparison_result TYPE zcl_abapgit_comparison_null.
  ENDMETHOD.


  METHOD zif_abapgit_object~delete.

    DATA: ls_icfservice TYPE icfservice.

    read( IMPORTING es_icfservice = ls_icfservice ).

    IF ls_icfservice IS INITIAL.
      " It seems that the ICF service doesn't exist anymore.
      " But that's ok, because some objects like SAPC manage
      " the lifecycle of its ICF service by itself and already
      " deleted the service.
      RETURN.
    ENDIF.

    IF ls_icfservice-icfparguid CO '0'.
* not supported by the SAP standard API
      zcx_abapgit_exception=>raise( 'SICF - cannot delete root node, delete node manually' ).
    ENDIF.

    cl_icf_tree=>if_icf_tree~delete_node(
      EXPORTING
        icfparguid                  = ls_icfservice-icfparguid
      CHANGING
        icf_name                    = ls_icfservice-icf_name
      EXCEPTIONS
        no_virtual_host_delete      = 1
        special_service_error       = 2
        enqueue_error               = 3
        node_not_existing           = 4
        node_has_childs             = 5
        node_is_aliased             = 6
        node_not_in_original_system = 7
        transport_error             = 8
        tadir_error                 = 9
        db_error                    = 10
        no_authority                = 11
        OTHERS                      = 12 ).
    IF sy-subrc <> 0.
      zcx_abapgit_exception=>raise( 'SICF - error from delete_node' ).
    ENDIF.

  ENDMETHOD.                    "delete


  METHOD zif_abapgit_object~deserialize.

    DATA: ls_icfservice TYPE icfservice,
          ls_read       TYPE icfservice,
          ls_icfdocu    TYPE icfdocu,
          lv_url        TYPE string,
          lv_exists     TYPE abap_bool,
          lt_icfhandler TYPE TABLE OF icfhandler.


    io_xml->read( EXPORTING iv_name = 'URL'
                  CHANGING cg_data = lv_url ).
    io_xml->read( EXPORTING iv_name = 'ICFSERVICE'
                  CHANGING cg_data = ls_icfservice ).
    io_xml->read( EXPORTING iv_name = 'ICFDOCU'
                  CHANGING cg_data = ls_icfdocu ).
    io_xml->read( EXPORTING iv_name = 'ICFHANDLER_TABLE'
                  CHANGING cg_data = lt_icfhandler ).


    lv_exists = zif_abapgit_object~exists( ).
    IF lv_exists = abap_false.
      insert_sicf( is_icfservice = ls_icfservice
                   is_icfdocu    = ls_icfdocu
                   it_icfhandler = lt_icfhandler
                   iv_package    = iv_package
                   iv_url        = lv_url ).
    ELSE.
      read( IMPORTING es_icfservice = ls_read ).
      change_sicf( is_icfservice = ls_icfservice
                   is_icfdocu    = ls_icfdocu
                   it_icfhandler = lt_icfhandler
                   iv_package    = iv_package
                   iv_parent     = ls_read-icfparguid ).
    ENDIF.

  ENDMETHOD.                    "deserialize


  METHOD zif_abapgit_object~exists.

    DATA: ls_tadir TYPE tadir,
          ls_key   TYPE ty_sicf_key.

    ls_tadir = read_tadir_sicf( ms_item-obj_name ).

    rv_bool = boolc( NOT ls_tadir IS INITIAL ).

    IF rv_bool = abap_true.
      ls_key = ls_tadir-obj_name.
      SELECT SINGLE icfaltnme FROM icfservice INTO ls_key-icf_name
        WHERE icf_name = ls_key-icf_name
        AND icfparguid = ls_key-icfparguid.
      rv_bool = boolc( sy-subrc = 0 ).
    ENDIF.

  ENDMETHOD.                    "zif_abapgit_object~exists


  METHOD zif_abapgit_object~get_metadata.
    rs_metadata = get_metadata( ).
  ENDMETHOD.                    "zif_abapgit_object~get_metadata


  METHOD zif_abapgit_object~has_changed_since.
    rv_changed = abap_true.
  ENDMETHOD.  "zif_abapgit_object~has_changed_since


  METHOD zif_abapgit_object~jump.

    DATA: ls_bcdata TYPE bdcdata,
          lt_bcdata TYPE STANDARD TABLE OF bdcdata.

    ls_bcdata-program  = 'RSICFTREE'.
    ls_bcdata-dynpro   = '1000'.
    ls_bcdata-dynbegin = 'X'.
    APPEND ls_bcdata TO lt_bcdata.

    ls_bcdata-dynpro   = space.
    ls_bcdata-dynbegin = space.
    ls_bcdata-fnam     = 'ICF_SERV'.
    ls_bcdata-fval     = ms_item-obj_name.
    APPEND ls_bcdata TO lt_bcdata.

    ls_bcdata-fnam = 'BDC_OKCODE'.
    ls_bcdata-fval = '=ONLI'.
    APPEND ls_bcdata TO lt_bcdata.

    CALL FUNCTION 'ABAP4_CALL_TRANSACTION'
      STARTING NEW TASK 'GIT'
      EXPORTING
        tcode     = 'SICF'
        mode_val  = 'E'
      TABLES
        using_tab = lt_bcdata
      EXCEPTIONS
        OTHERS    = 1.

    IF sy-subrc <> 0.
      zcx_abapgit_exception=>raise( 'error from ABAP4_CALL_TRANSACTION, SICF' ).
    ENDIF.

  ENDMETHOD.                    "jump


  METHOD zif_abapgit_object~serialize.

    DATA: ls_icfservice TYPE icfservice,
          ls_icfdocu    TYPE icfdocu,
          lv_url        TYPE string,
          lt_icfhandler TYPE TABLE OF icfhandler.


    read( IMPORTING es_icfservice = ls_icfservice
                    es_icfdocu    = ls_icfdocu
                    et_icfhandler = lt_icfhandler
                    ev_url        = lv_url ).
    IF ls_icfservice IS INITIAL.
      RETURN.
    ENDIF.

    CLEAR ls_icfservice-icfnodguid.
    CLEAR ls_icfservice-icfparguid.
    CLEAR ls_icfservice-icf_user.
    CLEAR ls_icfservice-icf_cclnt.
    CLEAR ls_icfservice-icf_mclnt.

    io_xml->add( iv_name = 'URL'
                 ig_data = lv_url ).
    io_xml->add( iv_name = 'ICFSERVICE'
                 ig_data = ls_icfservice ).
    io_xml->add( iv_name = 'ICFDOCU'
                 ig_data = ls_icfdocu ).
    io_xml->add( iv_name = 'ICFHANDLER_TABLE'
                 ig_data = lt_icfhandler ).

  ENDMETHOD.                    "serialize
ENDCLASS.
