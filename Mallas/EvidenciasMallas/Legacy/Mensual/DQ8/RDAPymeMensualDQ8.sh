#!/bin/bash
# ========================================================================================
#                                md_carterizador
#
#   Descripcion: ejecuta los procesos de controles RDA y PYME mensual
#                y genera los reportes.
#
#   Fecha: 17/Septiembre/2021
#   Desarrollo: JCJY
#   Fecha Modificacion: _______________
#   Modificado por: ___________________
#
#
# ========================================================================================

fechaodate=$PARM1
fechaodate2=$PARM2

#***************************** DECLARACION DE FUNCIONES ****************************

fDate()
{
  /bin/date +"%Y%m%d_%H%M"
}

fPurge()
{
  path=$1
  keep_file_num=$2
  echo "Eliminando archivos "
  echo "Ruta borra archivos  $path"

  total_files=`/bin/ls -ltr $path | /bin/grep ^- | /usr/bin/wc -l `
  echo "Num Archivos $total_files"

  let num_to_delete=$total_files-$keep_file_num
  echo "Resto $num_to_delete"

  if [ ${num_to_delete} -gt 0 ];
   then
       for i in $(/bin/ls -tr $path | /usr/bin/head -n $num_to_delete)
       do
        /bin/rm -f $i
        echo "$i" "Archivo Borrado"
       done
  fi
}

fError()
{
        echo "#---$(fDate) ERROR: -EXISTE ERROR- STOP"  >> $LOGFILE
        echo "#---$(fDate) ERROR: SAS $PASO"
        exit 1
}

#****************************** INICIA PROCESO ******************************************

PASO_00()
{
        PASO=RDA_PYME_DQ8
        echo "#---$(fDate) Iniciar: SAS $PASO"  >> $LOGFILE

        $SASGD94 $PATH/$PASO.sas -log $DSLOGS/${PASO}_SAS_$(fDate).log -print $DSLOGS/${PASO}_$(fDate).lst -work $APPWORK
        status=$?
        /bin/chmod 777 $DSLOGS/${PASO}_SAS_$(fDate).log
        /bin/chmod 777 $DSLOGS/${PASO}_$(fDate).lst
        echo "El codigo de salida es:" $status
        if [ $status -ne 0 ];
        then
                fError
        else
                echo "#---$(fDate) Completado con exito: SAS $PASO"  >> $LOGFILE
                fPurge "$DSLOGS/${PASO}_*.l*" "3"
                /bin/chmod 777 /SREPGRM/DQLEGACY_RIESGOS/MENSUAL/*DQ8*.*
                /bin/mv -f /SREPGRM/RDA_Pyme/Input/"Cuadro de Mandos $fechaodate.xlsx" /SREPGRM/RDA_Pyme/Input/"_Cuadro de Mandos $fechaodate.xlsx"
                /bin/mv -f /SREPGRM/RDA_Pyme/Input/"Metricos Originacion PyME $fechaodate.xlsx" /SREPGRM/RDA_Pyme/Input/"_Metricos Originacion PyME $fechaodate.xlsx"
                /bin/mv -f /SREPGRM/RDA_Pyme/Input/Vol-Cal_PyME_0$fechaodate2.xlsx /SREPGRM/RDA_Pyme/Input/_Vol-Cal_PyME_0$fechaodate2.xlsx
            exit 0
        fi
}

SASGD94="/sasgrid94/SASHome/SASFoundation/9.4/sas"
DSLOGS="/SREPGRM/Shells/Logs"
PATH="/SREPGRM/RDA_Pyme/Codigos"
FILENAM="R00_INC_RDA"
APPWORK="/mexmetodologias/work/"

LOGFILE=$DSLOGS/${FILENAM}_$(fDate).log

echo "#---$(fDate) INICIA PROCESO RDA_Pyme MENSUAL"  >> $LOGFILE
echo "***********************************************************************************************" >> $LOGFILE
echo "*                                   PROCESO RDA PYME MENSUAL                                   *" >> $LOGFILE
echo "*                            FECHA: " `/bin/date '+dia: %d/%m/%Y hora:%H:%M:%S'` "            *" >> $LOGFILE
echo "***********************************************************************************************" >> $LOGFILE

PASO_00>>$LOGFILE 2>>$LOGFILE
