while getopts "b:r:s:a:" opt; do
  case "$opt" in
    a)
      ACCOUNT=$OPTARG
      echo $ACCOUNT
      ;;
    b)
      BUCKET=$OPTARG
      echo $BUCKET
      ;;
    r)
      REGION=$OPTARG
      echo $REGION
      ;;
    s)
      STAGE=$OPTARG
      echo $STAGE 
      ;;
  esac
done

echo $1

echo $((OPTIND))

# shift $((OPTIND-1))

shift 3

echo $((OPTIND))

echo $1
