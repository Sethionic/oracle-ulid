CREATE OR REPLACE PACKAGE LUTOOLS.Ulid IS

    -- Author  : 
    -- Created : 8/20/2020 6:18:38 PM
    -- Purpose : 

    Nls_Timestamp_Format    VARCHAR2(64) := 'YYYY-MM-DD"T"HH24:MI:SS.ff3"Z"';
    Nls_Timestamp_Tz_Format VARCHAR2(64) := 'YYYY-MM-DD"T"HH24:MI:SS.ff3"Z"';

    TYPE B32_Map_Typ IS TABLE OF NUMBER INDEX BY VARCHAR2(1);
    B32map B32_Map_Typ;

    TYPE B32_Map_r_Typ IS TABLE OF varchar2(1) INDEX BY pls_integer;
    B32_r_map B32_Map_r_Typ;

    c_Base   NUMBER := 32;
    c_Base32 VARCHAR2(32) := '0123456789ABCDEFGHJKMNPQRSTVWXYZ'; --Crockford's base32

    FUNCTION Get_Ulid_Ts(p_In VARCHAR2) RETURN TIMESTAMP
        WITH TIME ZONE DETERMINISTIC;
        
        FUNCTION Get_Ts_ulid(p_In timestamp,p_tz varchar2 default 'America/New_York') RETURN varchar2 DETERMINISTIC;

END Ulid;
/

CREATE OR REPLACE PACKAGE BODY LUTOOLS.Ulid IS

    FUNCTION Get_Ulid_Ts(p_In VARCHAR2) RETURN TIMESTAMP
        WITH TIME ZONE DETERMINISTIC IS
        Dec_Value   NUMBER := 0;
        t_Time_Part VARCHAR2(10) := Substr(p_In, 0, 10); --First 10 characters are the timestamp
        Ret         TIMESTAMP WITH TIME ZONE := To_Timestamp_Tz('19700101 +00:00', 'yyyymmdd TZH:TZM');
    
    BEGIN
        --convert base 32 to base 10
        FOR i IN 1 .. Length(t_Time_Part)
        LOOP
            Dec_Value := Dec_Value +
                         Power(c_Base, i - 1) *
                         B32map(Substr(t_Time_Part, -i, 1));
        END LOOP;
        --add to unix timestamp sentinal
        Ret := Ret + Numtodsinterval(((Dec_Value / 1000)), 'SECOND');
        RETURN Ret;
    END;
    
    FUNCTION Get_Ts_ulid(p_In timestamp,p_tz varchar2 default 'America/New_York') RETURN varchar2
        DETERMINISTIC IS
        Dec_Value   NUMBER := 0;
        --t_Time_Part VARCHAR2(10) := Substr(p_In, 0, 10); --First 10 characters are the timestamp
        t_sentinal         TIMESTAMP WITH TIME ZONE := To_Timestamp_Tz('19700101 +00:00', 'yyyymmdd TZH:TZM');
        t_placeholder date := cast(t_sentinal as date);
        t_step number;
        t_divisor number;
        t_quotient number;
        t_mapped varchar2(1);
        ret varchar2(10);
    
    BEGIN
        --Subtract sentinal from input timestamp and convert to microseconds
        dec_value:= ( (cast ( ( from_tz(p_in,p_tz) at time zone 'UTC' ) as date) - t_placeholder)*86400*1000);
        --dec_value:=round(dec_value,0);
        --select ( (cast ((p_in at time zone p_tz) as date) - t_placeholder)*86400) into dec_value from dual;
        --convert base 10 to base 32
        dbms_output.put_line(dec_value);
        FOR i IN 1 .. 10
        LOOP
            t_step := 10-i;
            t_divisor:=Power(c_Base, t_step);
            t_quotient:=trunc( dec_value / t_divisor );
            t_mapped:=b32_r_map(   t_quotient   );
            ret:=ret||t_mapped;

            --dbms_output.put_line(dec_value||'/'||t_divisor||' ['||c_base||'^'||(t_step-1)||'] = '||t_quotient||' => '||t_mapped);

            dec_value:=dec_value-t_quotient*t_divisor;
            /*Dec_Value := Dec_Value +
                         Power(c_Base, i - 1) *
                         B32map(Substr(t_Time_Part, -i, 1));*/
        END LOOP;
        RETURN ret; --rpad(Ret,16,'0');
    END;

BEGIN
    --initialize base32 map
    FOR i IN 0 .. Length(c_Base32) - 1
    LOOP
        B32map(Substr(c_Base32, i + 1, 1)) := i;
        B32_r_map(i) := Substr(c_Base32, i + 1, 1);
    END LOOP;
    
      /*select interval_difference
      ,sysdate + (interval_difference * 86400) - sysdate as fract_sec_difference
      from   (select systimestamp - (systimestamp - 1) as interval_difference
      from   dual)*/

END Ulid;
/
