# AFFI Poor man's simple foreign function calls
# J�rg H�hle 11.8.1996

#include "lispbibl.c"
# TODO? check offset against number of library vectors
# TODO: LISPFUN(%CHECK-PROTO) by calling a do-nothing function
# TODO: LISPFUN(VALIDP)             \
# TODO: LISPFUN(INVALIDATE-FOREIGN)  +- useful with FINALIZE
# TODO: LISPFUN(FOREIGN-NULLP)      /

#ifdef HAVE_AFFI

# die Moduldefinition ist am Dateiende

#ifdef MC680X0
  #undef HAVE_REG_FF_CALL
  #define HAVE_REG_FF_CALL

  #define reg_num  15
  #define reg_coding 4 # used bits in mask
  struct reg_map { ULONG reg[reg_num]; }; # d0-7,a0-6. a7 ist sp und nicht belegbar

  #ifdef AMIGAOS
    #define libbase_reg 14 # a6 wird mit der Librarybase belegt
  #endif

  #if defined(GNU) && !defined(NO_ASM)
  local ULONG reg_call (aint address, const struct reg_map *);
  local ULONG reg_call(address, regs)
    var aint address;
    var const struct reg_map* regs;
    { var ULONG result  __asm__("d0");
  #if 1 # DEBUG
      begin_system_call();
      asm("
          moveml #0x3f3e,sp@-     | d2-d7,a2-a6
        | pea pc@(Lgoon)          | ATTN: BUG: previous gas needed pc@(Lgoon+2)
          pea Lgoon               | ATTN: BUG: as-2.5.x makes 68020 code for pea pc@(Lgoon)
          movel %1,sp@-           | where to jump
          moveml %2@,#0x7fff      | a6-a0,d7-d0
          rts                     | jump
  Lgoon:
          moveml sp@+,#0x7cfc     | a6-a2,d7-d2
  "
          : "=d" (result)
          : "r" (address), "a" (regs)
          : "memory");
      end_system_call();
  #elif 0
      begin_system_call();
      asm("
          moveml #0x3f3e,sp@-     | d2-d7,a2-a6
          movel %1,sp@-           | where to jump
          moveml %2@,#0x7fff      | a6-a0,d7-d0
          jbsr sp@(4)             | call function - sp@ or sp@(4) ??
          addqw #4,sp             | pop address
          moveml sp@+,#0x7cfc     | a6-a2,d7-d2
  "
          : "=d" (result)
          : "r" (address), "a" (regs)
          : "memory");
      end_system_call();
  #else
      var uintC count = reg_num;
      asciz_out_1("Sprungadresse %x\n",address);
      dotimesC(count,count,
        { asciz_out_2("%d: %x\n",count,regs->reg[count]); });
      result = regs->reg[0];
  #endif # DEBUG
      return result;
    }
  #endif # GNU
#endif # MC680X0


# stattdessen fehler_funspec verwenden?
nonreturning_function(local, fehler_ffi_nocall, (object ffinfo));
local void fehler_ffi_nocall(ffinfo)
  var object ffinfo;
  { pushSTACK(ffinfo); pushSTACK(TheSubr(subr_self)->name);
    fehler(error,
           GETTEXT("~: Unsupported call mechanism: ~")
          );
  }

nonreturning_function(local, fehler_ffi_proto, (object ffinfo));
local void fehler_ffi_proto(ffinfo)
  var object ffinfo;
  { pushSTACK(ffinfo);
    pushSTACK(TheSubr(subr_self)->name);
    fehler(error,
           GETTEXT("~: Bad function prototype: ~")
          );
  }

nonreturning_function(local, fehler_ffi_argcount, (object ffinfo));
local void fehler_ffi_argcount(ffinfo)
  var object ffinfo;
  { pushSTACK(ffinfo);
    pushSTACK(TheSubr(subr_self)->name);
    fehler(program_error,
           GETTEXT("~: Wrong number of arguments for prototype ~")
          );
  }

nonreturning_function(local, fehler_ffi_argtype, (object obj, object type, object ffinfo));
local void fehler_ffi_argtype(obj,type,ffinfo)
  var object obj;
  var object type; # wird nur unpr�zise verwendet
  var object ffinfo;
  { pushSTACK(obj); # Wert f�r Slot DATUM von TYPE-ERROR
    pushSTACK(fixnump(type) ? S(integer) : T); # Wert f�r Slot EXPECTED-TYPE von TYPE-ERROR
    pushSTACK(obj); pushSTACK(ffinfo); pushSTACK(TheSubr(subr_self)->name);
    fehler(type_error,
           GETTEXT("~: Bad argument for prototype ~: ~")
          );
  }

#define fehler_ffi_type  fehler_ffi_arg
nonreturning_function(local, fehler_ffi_arg, (object obj));
local void fehler_ffi_arg(obj)
  var object obj;
  { pushSTACK(obj); pushSTACK(TheSubr(subr_self)->name);
    fehler(control_error,
           GETTEXT("~: Bad argument: ~")
          );
  }

# Lese g�ltige Adresse inklusive Offset
local aint convert_address (object obj, object offset);
local aint convert_address(obj, offset)
  var object obj;
  var object offset;
  { var aint address = 0;
    if (uint32_p(obj))
      { address = I_to_UL(obj); }
    elif (fpointerp(obj) && fp_validp(TheFpointer(obj)))
      { address = (aint)(TheFpointer(obj)->fp_pointer); }
    if (address == 0)
      { pushSTACK(obj); # Wert f�r Slot DATUM von TYPE-ERROR
        pushSTACK(S(unsigned_byte)); # Wert f�r Slot EXPECTED-TYPE von TYPE-ERROR
        pushSTACK(obj); pushSTACK(TheSubr(subr_self)->name);
        fehler(type_error,
               GETTEXT("~: ~ is not a valid address")
              );
      }
    if (!eq(offset,unbound))
      { address += I_to_L(offset); }
    return address;
  }


#if defined(HAVE_LONGLONG) && 1 # ben�tigt Funktionen aus INTELEM.D und LISPBIBL.D
#define uintbig  uint64
#define uintbig_p(obj)  uint64_p(obj) # reicht f�r reg_num <= 16 (AmigaOS)
#define I_to_Ubig(obj)  I_to_UQ(obj)
#else
#define uintbig  uintL
#define uintbig_p(obj)  uint32_p(obj) # reicht nicht f�r reg_num > 8
#define I_to_Ubig(obj)  I_to_UL(obj)
#endif

# F�hrt Funktionsaufruf aus und erzeugt LISP-Ergebnis.
# Die Argumente m�ssen zuvor �berpr�ft worden sein (Typ und Zahl)
# < value1, mv_count
local void affi_callit (aint address, object ffinfo, aint* args);
local void affi_callit(address, ffinfo, args)
  var aint address;
  var object ffinfo;
  var aint* args;
  { var sintL offset;
    var object mask;
    var aint thing;
    { var object both = TheSvector(ffinfo)->data[0];
      if (nullp(both))
        { mask = NIL;
          offset = 0;
        }
      elif (consp(both))
        { mask = Cdr(both);
          offset = I_to_L(Car(both)); # nur fixnum_to_L() (dann mit �berpr�fung) ?
        }
      else goto bad_proto;
    }
    if (nullp(mask))
      { # Stack-based call mechanism
        #ifdef HAVE_STACK_FF_CALL
        thing = stack_call(address+offset,args,ffinfo);
        #else
        goto bad_call;
        #endif
      }
    elif (integerp(mask))
      { # Register-based call mechanism
        #ifdef HAVE_REG_FF_CALL
        var struct reg_map regs;
        if (uintbig_p(mask))
          {
            var uintC count = Svector_length(ffinfo)-2;
            #ifdef AMIGAOS # Always fill a6 with possible library base address
            regs.reg[libbase_reg] = address;
            #endif
            if (eq(mask,Fixnum_0))
              { if (count!=0) goto bad_proto; }
              else
              { var unsigned_int_with_n_bits(reg_num) used = 0;
                var uintbig lowmask = I_to_Ubig(mask);
                dotimesC(count,count,
                  { var uintBW index = (lowmask & (bit(reg_coding)-1));
                    index = index-1; # 0 gilt nicht als Index
                    if (index >= reg_num || bit_test(used,index)) goto bad_proto;
                    used |= bit(index);
                    regs.reg[index] = *args++;
                    lowmask >>= reg_coding;
                  });
                if (lowmask!=0) goto bad_proto;
          }   }
        else goto bad_proto;
        # Regcall ausf�hren
        thing = reg_call(address+offset,&regs);
        #else
        goto bad_call;
        #endif
      }
    else
      { bad_proto:
        fehler_ffi_proto(ffinfo);
        bad_call:
        fehler_ffi_nocall(ffinfo);
      }
    # Aufruf erfolgreich, Werte setzen
    # Ergebnis kann bei GC (wegen String oder Bignum) und RESET verloren gehen
    { var object rtype = TheSvector(ffinfo)->data[1];
      if (eq(rtype,NIL))
        { mv_count=0; value1 = NIL; }
        else
        { if (fixnump(rtype))
            { switch(fixnum_to_L(rtype))
                { case  4L: value1 = UL_to_I(thing); break;
                  case  2L: value1 = UL_to_I((uint16)thing); break;
                  case  1L: value1 = UL_to_I((uint8)thing); break;
                  case  0L: value1 = thing ? T : NIL; break; # Typ BOOL
                  case -1L: value1 = L_to_I((sint8)thing); break;
                  case -2L: value1 = L_to_I((sint16)thing); break;
                  case -4L: value1 = L_to_I(thing); break;
                  # andere F�lle wurde schon mit Fehler abgefangen
                  default: value1 = NIL;
            }   }
          elif (eq(rtype,S(string)))    # string
            { value1 = (thing == 0 ? NIL : asciz_to_string((const char*)thing,O(foreign_encoding))); }
          elif (eq(rtype,S(mal)))       # *
            { value1 = UL_to_I(thing); }
          elif (eq(rtype,S(Kexternal))) # :external
            { value1 = (thing == 0 ? NIL : allocate_fpointer((FOREIGN)thing)); }
          # andere F�lle wurden schon mit Fehler abgefangen
          else { value1 = NIL; }
          mv_count=1;
  } }   }


# F�hrt Typ�berpr�fungen und Aufruf aus. Ermittelt dabei und belegt
# mittels alloca() die Gr��e des Bereichs f�r die LISP-STRING nach C
# (asciz) Umwandlung
# Darf bis zum Aufruf keine GC ausl�sen.
# < value1, mv_count
local void affi_call_argsa (aint address, object ffinfo, const object* args, uintC count);
local void affi_call_argsa(address, ffinfo, args, count)
  var aint address;
  var object ffinfo;
  var const object* args;
  var uintC count;
  { # if (!simple_vector_p(ffinfo)) goto bad_proto; # oder fehler_kein_svector();
    # Zahl der Argumente �berpr�fen
    { var uintL vlen = Svector_length(ffinfo);
      if (vlen != count+2) { fehler_ffi_argcount(ffinfo); }
    }
    # Return-Type schon vor dem Aufruf �berpr�fen
    { var object rtype = TheSvector(ffinfo)->data[1];
      if (fixnump(rtype))
        { var sintL size = fixnum_to_L(rtype);
          if (size < 0) { size = -size; }
          if (size > 4 || size == 3) goto bad_proto;
        }
      elif (!( nullp(rtype) || eq(rtype,S(mal)) || eq(rtype,S(Kexternal)) || eq(rtype,S(string)) )) goto bad_proto;
    }
    # Typpr�fung und Speicherung (auf Stack SP) der Argumente
    #define ACCEPT_ADDR_ARG      bit(0)
    #define ACCEPT_STRING_ARG    bit(1)
    #define ACCEPT_UBVECTOR_ARG  bit(2)
    #define ACCEPT_MAKE_ASCIZ    bit(3)
    #define ACCEPT_NIL_ARG       bit(4)
    #define ACCEPT_NUM_ARG       bit(5)
    { var DYNAMIC_ARRAY(things,aint,count);
      if (count > 0)
        { var const object* types = &TheSvector(ffinfo)->data[2];
          var aint* thing = &things[0];
          dotimespC(count,count,
            { var object type = *types++;
              var object arg = NEXT(args);
              if (fixnump(type))
                { if (integerp(arg))
                    { switch (fixnum_to_L(type))
                        { case 1L:
                            if (!uint8_p(arg)) goto bad_arg; # Fehlermeldung mit O(type_uint8) denkbar
                              else *thing = I_to_uint8(arg);
                            break;
                          case 2L:
                            if (!uint16_p(arg)) goto bad_arg;
                              else *thing = I_to_uint16(arg);
                            break;
                          case 4L:
                            if (!uint32_p(arg)) goto bad_arg;
                              else *thing = I_to_uint32(arg);
                            break;
                          case -1L:
                            if (!sint8_p(arg)) goto bad_arg;
                              else *thing = I_to_sint8(arg);
                            break;
                          case -2L:
                            if (!sint16_p(arg)) goto bad_arg;
                              else *thing = I_to_sint16(arg);
                            break;
                          case -4L:
                            if (!sint32_p(arg)) goto bad_arg;
                              else *thing = I_to_sint32(arg);
                            break;
                          default: goto bad_proto;
                    }   }
                    else
                    { bad_arg:
                      fehler_ffi_argtype(arg,type,ffinfo);
                }   }
                else # !fixnump(type)
                { var uintBWL accept;
                  if (eq(type,S(mal))) # Zeiger
                      { accept = ACCEPT_ADDR_ARG | ACCEPT_UBVECTOR_ARG | ACCEPT_STRING_ARG | ACCEPT_MAKE_ASCIZ | ACCEPT_NIL_ARG; }
                  elif (eq(type,S(string)))
                      { accept = ACCEPT_ADDR_ARG | ACCEPT_STRING_ARG | ACCEPT_MAKE_ASCIZ | ACCEPT_NIL_ARG; }
                  elif (eq(type,S(Kio)))
                      { accept = ACCEPT_ADDR_ARG | ACCEPT_UBVECTOR_ARG | ACCEPT_STRING_ARG; }
                  elif (eq(type,S(Kexternal)))
                      { accept = ACCEPT_ADDR_ARG | ACCEPT_NIL_ARG; }
                  else goto bad_proto;
                  #ifdef TYPECODES
                  switch (typecode(arg))
                  #else
                  if (posfixnump(arg)) { goto case_posfixnum; }
                  elif (orecordp(arg)) { goto case_orecord; }
                  else switch (0)
                  #endif
                    { case_posfixnum: case_posbignum:
                        if (!(accept & ACCEPT_ADDR_ARG)) goto bad_arg;
                        *thing = (aint)I_to_UL(arg);
                        break;
                      case_string:
                        if (!(accept & ACCEPT_STRING_ARG)) goto bad_arg;
                        # Cf. with_string_0() macro in lispbibl.d
                        { var uintL length;
                          var uintL offset;
                          var object string = unpack_string_ro(arg,&length,&offset);
                          var const chart* charptr;
                          unpack_sstring_alloca(string,length,offset, charptr=);
                          if (accept & ACCEPT_MAKE_ASCIZ)
                            { var uintL bytelength = cslen(O(foreign_encoding),charptr,length);
                              var uintB* ptr = alloca(1+bytelength); # TODO Ergebnis testen
                              *thing = (aint)ptr;
                              cstombs(O(foreign_encoding),charptr,length,ptr,bytelength);
                              ptr[bytelength] = '\0';
                            }
                            else
                            { var uintB* ptr = alloca(length); # TODO Ergebnis testen
                              *thing = (aint)ptr;
                              dotimesL(length,length, { *ptr++ = as_cint(*charptr++); } );
                              #error "Ich bin mir nicht sicher, ob das das Gew�nschte ist."
                              #error "Gibt es FFI-Bindings, die versuchen, in einen String hineinzuschreiben?"
                            }
                        }
                        break;
                      case_symbol:
                        if (!(accept & ACCEPT_NIL_ARG)) goto bad_arg;
                        if (!nullp(arg)) goto bad_arg;
                        *thing = (aint)0;
                        break;
                      case_orecord:
                        switch (Record_type(arg))
                          {
                            #ifndef TYPECODES
                            case Rectype_Bignum:
                              if (BN_positivep(arg)) goto case_posbignum;
                              goto bad_arg;
                            #endif
                            case_Rectype_string_above;
                            case_Rectype_Symbol_above;
                            case_Rectype_obvector_above;
                            case Rectype_Fpointer:
                              if (!(accept & ACCEPT_ADDR_ARG)) goto bad_arg;
                              if (fp_validp(TheFpointer(arg)))
                                { *thing = (aint)(TheFpointer(arg)->fp_pointer);
                                  break;
                                }
                              goto bad_arg;
                            default:
                              goto bad_arg;
                          }
                        break;
                      case_obvector:
                        if (!(accept & ACCEPT_UBVECTOR_ARG)) goto bad_arg;
                        { var uintBWL bsize = Iarray_flags(arg) & arrayflags_atype_mask;
                          if (!((bsize==Atype_8Bit) || (bsize==Atype_16Bit) || (bsize==Atype_32Bit))) goto bad_arg;
                         {var uintL index = 0;
                          arg = iarray_displace_check(arg,0,&index); # UNSAFE
                          *thing = (aint)&TheSbvector(TheIarray(arg)->data)->data[index];
                        }}
                        break;
                      default: goto bad_arg;
                }   }
              thing++;
            });
        }
      affi_callit(address,ffinfo,&things[0]);
      FREE_DYNAMIC_ARRAY(things);
      return;
    }
    bad_proto:
    fehler_ffi_proto(ffinfo);
  }

# (SYSTEM::%LIBCALL base ff-description &rest args)
# kann GC ausl�sen (nach erfolgtem Aufruf)
LISPFUN(affi_libcall,2,0,rest,nokey,0,NIL)
  { var object ffinfo = Before(rest_args_pointer); # #((offset . mask) return-type . arg-types*))
    var aint address = convert_address(Before(rest_args_pointer STACKop 1),unbound);
    if (!simple_vector_p(ffinfo))
      { fehler_kein_svector(TheSubr(subr_self)->name,ffinfo); }
    affi_call_argsa(address,ffinfo,rest_args_pointer,argcount);
    # value1 und mv_count wurden darin gesetzt
    set_args_end_pointer(rest_args_pointer STACKop 2);
  }


local void bytecopy (void* to, const void* from, uintL length, uintC size);
local void bytecopy(to,from,length,size)
  var void* to;
  var const void* from;
  var uintL length;
  var uintC size;
  { switch (size)
      { case 1: case 8:
          dotimespL(length,length, { *((UBYTE*)to)++ = *((UBYTE*)from)++; }); break;
        case 2: case 16:
          dotimespL(length,length, { *((UWORD*)to)++ = *((UWORD*)from)++; }); break;
        case 4: case 32:
          dotimespL(length,length, { *((ULONG*)to)++ = *((ULONG*)from)++; }); break;
        default:
          /* NOTREACHED */
  }   }

# (SYSTEM::MEM-READ address into [offset]) reads from address[+offset].
# can trigger GC
LISPFUN(mem_read,2,1,norest,nokey,0,NIL)
  { var aint address = convert_address(STACK_2,STACK_0);
    # TODO? address could be a LISP string or vector. Better not
    var object into = STACK_1; # Gr��e in Byte, '*, 'STRING, string oder vector
    skipSTACK(3);
    if (eq(into,S(mal))) # pointer dereference
      { value1 = UL_to_I(*(aint*)address); }
    elif (posfixnump(into))
      { var uintL content;
        switch (posfixnum_to_L(into))
          { case 1L: content = *(UBYTE *)address; break;
            case 2L: content = *(UWORD *)address; break;
            case 4L: content = *(ULONG *)address; break;
            default: goto fehler_type;
          }
        value1 = UL_to_I(content);
      }
    elif (fixnump(into))
      { var sintL content;
        switch (negfixnum_to_L(into))
          { case -1L: content = *(SBYTE *)address; break;
            case -2L: content = *(SWORD *)address; break;
            case -4L: content = *(SLONG *)address; break;
            default: goto fehler_type;
          }
        value1 = L_to_I(content);
      }
    elif (eq(into,S(string))) # make a LISP string
      { value1 = asciz_to_string((uintB*)address,O(foreign_encoding)); }
    elif (stringp(into)) # copy memory into a LISP string
      { var uintL length;
        var chart* charptr = unpack_string_rw(into,&length);
        if (length > 0)
          {
            #ifdef UNICODE
            var object encoding = O(foreign_encoding);
            var const uintB* byteptr = (uintB*)address;
            ASSERT(Encoding_mblen(encoding)(encoding,byteptr,byteptr+length) == length);
            Encoding_mbstowcs(encoding)(encoding,nullobj,&byteptr,byteptr+length,&charptr,charptr+length);
            ASSERT(byteptr == (uintB*)address+length);
            #else
            dotimespL(length,length, { *charptr++ = as_chart(*((uintB*)address)++); } );
            #endif
          }
        value1 = into;
      }
    elif (!bit_vector_p(into) # copy memory into a LISP unsigned-byte vector
          && general_byte_vector_p(into))
      { var uintBWL size = Iarray_flags(into) & arrayflags_atype_mask;
        if (!((size==Atype_8Bit) || (size==Atype_16Bit) || (size==Atype_32Bit))) { goto fehler_type; }
       {var uintL length = vector_length(into);
        if (length > 0)
          { var uintL index = 0;
            var object dv = iarray_displace_check(into,length,&index);
            bytecopy(&TheSbvector(TheIarray(dv)->data)->data[index],(void*)address,length,bit(size));
          }
        value1 = into;
      }}
    else
      { fehler_type:
        fehler_ffi_type(into);
      }
    mv_count=1;
  }


# (SYSTEM::MEM-WRITE address type value [offset]) writes to address[+offset].
LISPFUN(mem_write,3,1,norest,nokey,0,NIL)
  { var aint address = convert_address(STACK_3,STACK_0);
    var object wert = STACK_1;
    var object type = STACK_2; # Gr��e in Byte oder *
    skipSTACK(4);
    if (eq(type,S(mal))) # pointer dereference
      { if (integerp(wert))
          { *(aint*)address = I_to_UL(wert); }
        elif (fpointerp(wert))
          { *(aint*)address = (aint)TheFpointer(wert)->fp_pointer; }
        else goto bad_arg;
      }
    elif (!integerp(wert)) goto bad_arg;
    elif (posfixnump(type))
      { var ULONG value = I_to_UL(wert);
        switch (posfixnum_to_L(type))
          { case 1L: if (value & ~0xFF) goto bad_arg;
                     else *(UBYTE *)address = value; break;
            case 2L: if (value & ~0xFFFF) goto bad_arg;
                     else *(UWORD *)address = value; break;
            case 4L:      *(ULONG *)address = value; break;
            default: goto bad_type;
      }   }
    elif (fixnump(type))
      { var SLONG value = I_to_L(wert);
        switch (negfixnum_to_L(type)) # TODO valid range checks
          { case -1L: *(SBYTE *)address = value; break;
            case -2L: *(SWORD *)address = value; break;
            case -4L: *(SLONG *)address = value; break;
            default: goto bad_type;
      }   }
    else
      { bad_type:
        fehler_ffi_type(type);
        bad_arg:
        fehler_ffi_arg(wert);
      }
    value1 = NIL; mv_count=0;
  }

# (SYSTEM::MEM-WRITE-VECTOR address vector [offset]) writes string to address.
LISPFUN(mem_write_vector,2,1,norest,nokey,0,NIL)
  { var aint address = convert_address(STACK_2,STACK_0);
    var object from = STACK_1;
    skipSTACK(3);
    if (stringp(from)) # write a LISP string to memory
      { var uintL length;
        var uintL offset;
        var object string = unpack_string_ro(from,&length,&offset);
        var const chart* charptr;
        unpack_sstring_alloca(string,length,offset, charptr=);
       {var uintL bytelength = cslen(O(foreign_encoding),charptr,length);
        cstombs(O(foreign_encoding),charptr,length,(uintB*)address,bytelength);
        ((uintB*)address)[bytelength] = '\0'; # and zero-terminate memory!
      }}
    elif (!bit_vector_p(from) # copy memory into a LISP unsigned-byte vector
          && general_byte_vector_p(from))
      { var uintBWL size = Iarray_flags(from) & arrayflags_atype_mask;
        if (!((size==Atype_8Bit) || (size==Atype_16Bit) || (size==Atype_32Bit))) { goto fehler_type; }
       {var uintL length = vector_length(from);
        if (length > 0)
          { var uintL index = 0;
            var object dv = iarray_displace_check(from,length,&index);
            bytecopy((void*)address,&TheSbvector(TheIarray(dv)->data)->data[index],length,bit(size));
      }}  }
    else
      { fehler_type:
        fehler_ffi_type(from);
      }
    value1 = NIL; mv_count=0;
  }

# (SYSTEM::NZERO-POINTER-P pointer) returns NIL for either NIL, 0 or NULL fpointer
LISPFUN(affi_nonzerop,1,0,norest,nokey,0,NIL)
  { var object arg = popSTACK();
   #if 0
    # TODO? error if other data type
    if (nullp(arg)
        || eq(arg,Fixnum_0)
        || (fpointerp(arg) && (TheFpointer(arg)->fp_pointer == (void*)0)))
      { value1 = NIL; }
    else
      { value1 = T; }
   #else
    #ifdef TYPECODES
    switch (typecode(arg))
    #else
    if (posfixnump(arg)) { goto case_posfixnum; }
    elif (orecordp(arg)) { goto case_orecord; }
    else switch (0)
    #endif
      { case_posfixnum: case_posbignum:
          value1 = (eq(arg,Fixnum_0) ? NIL : T);
          break;
        case_orecord:
          switch (Record_type(arg))
            { case_Rectype_Symbol_above;
              case Rectype_Fpointer:
                value1 = ((TheFpointer(arg)->fp_pointer == (void*)0) ? NIL : T);
                break;
              #ifndef TYPECODES
              case Rectype_Bignum:
                if (BN_positivep(arg)) goto case_posbignum;
                # fall through
              #endif
              default:
                fehler_ffi_arg(arg);
            }
          break;
        case_symbol:
          if (nullp(arg))
            { value1 = NIL;
              break;
            }
          # fall through
        default:
          fehler_ffi_arg(arg);
      }
   #endif
    mv_count=1;
  }


#ifdef AFFI_MODULE

# Moduldefinitionen

uintC module__affi__object_tab_size = 0;
object module__affi__object_tab[1];
object_initdata module__affi__object_tab_initdata[1];

#undef LISPFUN
#define LISPFUN LISPFUN_F
#undef LISPSYM
#define LISPSYM(name,printname,package)  { package, printname },
#define system  "SYSTEM"

#define subr_anz  5

uintC module__affi__subr_tab_size = subr_anz;

subr_ module__affi__subr_tab[subr_anz] = {
  LISPFUN(affi_libcall,2,0,rest,nokey,0,NIL)
  LISPFUN(mem_read,2,1,norest,nokey,0,NIL)
  LISPFUN(mem_write,3,1,norest,nokey,0,NIL)
  LISPFUN(mem_write_vector,2,1,norest,nokey,0,NIL)
  LISPFUN(affi_nonzerop,1,0,norest,nokey,0,NIL)
};

subr_initdata module__affi__subr_tab_initdata[subr_anz] = {
  LISPSYM(affi_libcall,"%LIBCALL",system)
  LISPSYM(mem_read,"MEM-READ",system)
  LISPSYM(mem_write,"MEM-WRITE",system)
  LISPSYM(mem_write_vector,"MEM-WRITE-VECTOR",system)
  LISPSYM(affi_nonzerop,"NZERO-POINTER-P",system)
};

# called once when module is initialized, not called if found in .mem file
void module__affi__init_function_1(module)
  var module_* module;
  { # evtl. keywords-Slot m�ssten wir initialisieren
  }

# called for every session
void module__affi__init_function_2(module)
  var module_* module;
  {
  }

# If we had a module exit function, we could close all libraries the programmer
# forgot.

#endif # AFFI_MODULE

#endif # HAVE_AFFI
