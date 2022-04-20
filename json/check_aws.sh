#!/bin/bash

if [ $# -lt 5 ]
then
  echo "error"
  exit $UNKNOWN
else
  SERVICE="$1"
  AWSSERVICE="$2"
  METRIC="$3"
  CRITICALTHRESHOLD="$4"
  shift
  shift
  shift
  shift
  ALARMNAME=$*
fi

echo "$*"

TMPDIR=/tmp/cloudwatch_alarms

OK=0
WARNING=1
CRITICAL=2
UNKNOWN=3

ALARMNAMETRIM=$(echo "${ALARMNAME}" | sed "s/ //g")

echo "ALARMNAMETRIM: ${ALARMNAMETRIM}"

OUTFILE=/tmp/outfile.${SERVICE}.${METRIC}.${ALARMNAMETRIM}.${CRITICALTHRESHOLD}.tmp

if [ ! -e ${ALARMSFILE} ];then
  exit ${UNKNOWN}
fi

cat ${ALARMSFILE} | jq "select(.namespace==\"${AWSSERVICE}\" and .state==\"ALARM\" and .metric==\"${METRIC}\" and .name==\"${ALARMNAME}\")" > ${OUTFILE}

result=`wc -c < ${OUTFILE}`
count=`grep -o -e "\"state\":\s*\"ALARM\"" ${OUTFILE} | wc -l`

if [ ${result} -gt 0 ];then
  if [ ${ALARMNAME: -4} == "logs" ];then
    ALARMTIME=$(date)
    ENDTIME=$(date -d "${ALARMTIME}" +"%s")
    STARTTIME=$(date -d "${ALARMTIME} 2 minutes ago" +"%s")
    aws logs describe-metric-filters --region ${REGION} --metric-namespace ${AWSSERVICE} --metric-name ${METRIC} | jq -r '.metricFilters[] | .filterPattern'| sed -e 's/"/\"/g' | while read logfilters
    do
      aws logs filter-log-events --region ${REGION} --log-group-name ${AWSSERVICE} --filter-pattern "$logfilters" --start-time ${STARTTIME}000 --end-time ${ENDTIME}000 --max-items 1 |jq -c '.events[] | {logStream:.logStreamName,message:.message}' | sed -e 's/\\\\n/ /g' -e 's/\\"/ /g' >> ${OUTFILE}.${STARTTIME}.logs
    done
    cat  ${OUTFILE}.${STARTTIME}.logs | tr '\n' ',' > ${OUTFILE}
  fi
  if [ ${count} -ge ${CRITICALTHRESHOLD} -a ${CRITICALTHRESHOLD} -ne 0 ];then
    echo -n "${AWSSERVICE} ${METRIC} ${ALARTNAME} CRITICAL - ${count} alarms occurred: "
    cat ${OUTFILE}
    exit ${CRITICAL}
  else
    echo -n "${AWSSERVICE} ${METRIC} ${ALARTNAME} WARNING - ${count} alarm occurred: "
    cat ${OUTFILE}
    exit ${WARNING}
  fi
else
  echo "${AWSSERVICE} ${METRIC} ${ALARTNAME} OK - 0 alarm occurred."
  exit ${OK}
fi

echo "** Script Execution Error **"
exit $UNKNOWN

