#!/usr/bin/env bash
set -e
echo "This is a script to delete obsolete meilix iso builds by Abishek V Ashok"
echo "You have to add an authorization token to make it functional."

# jq is the JSON parser we will be using
sudo apt-get -qq -y install jq

# Storing the response to a variable for future usage
response=`curl https://api.github.com/repos/fossasia/meilix/releases | jq '.[] | .published_at, .id'`

# Sample response:
#   response = 
#   "2017-12-11T11:48:12Z"
#   8851595
#   "2017-12-11T11:41:52Z"
#   8851565
#   "2017-12-11T07:55:12Z"
#   8848715
#   "2017-12-01T00:15:29Z"
#   8727275

index=1  # when index is odd, $i contains id and when it is even $i contains published_date
delete=0 # Should we delete the release?
current_year=`date +%Y`  # Current year eg) 2001
current_month=`date +%m` # Current month eg) 2
current_day=`date +%d`   # Current date eg) 24

for i in $response; do
    if [ $((index % 2)) -eq 1 ]; then # We get the published_date of the release as $i's value here
        published_year=${i:1:4}
        published_month=${i:6:2}
        published_day=${i:9:2}

        if [ $published_year -lt $current_year ]; then
              echo "Release was made before this year, deleting:"
              delete=1
        else
            echo "Release was made this year, trying to compare month"
            if [ $published_month -lt $current_month ]; then
                echo "Release was made before more than a month, deleting:"
                delete=1
            else
                echo "Release was made this month, trying to compare date"
                day_count=`expr $current_day - $published_day`
                if [ $day_count -gt 10 ]; then
                    echo "Release was made before more than 10 days, deleting:"
                    delete=1
                else
                    echo "Release was made within the last 10 days, not deleting:"
                    delete=0
                fi
            fi
        fi
    else # We get the id of the release as $i`s value here
        echo $i
        if [ $delete -eq 1 ]; then
            curl -u "$UNAME":"$KEY" -X DELETE https://api.github.com/repos/fossasia/meilix/releases/$i
            delete=0
        fi
    fi
    let "index+=1"
done
