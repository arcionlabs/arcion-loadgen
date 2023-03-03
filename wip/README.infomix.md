https://hub.docker.com/r/ibmcom/informix-developer-database/

sign up [IBM Informix Developer Edition](https://www.ibm.com/products/informix/editions?lnk=STW_US_STESCH_&lnk2=learn_InformixDev&pexp=DEF&psrc=NONE&mhsrc=ibmsearch_a&mhq=informix%20developer%20edition
)

https://github.com/merajabi/informix-tutorial-step-by-step-guide-for-beginners

docker pull ibmcom/informix-developer-database

docker run -d --name ifx  -h ifx --network arcnet \
      -p 9088:9088 \
      -p 9089:9089 \
      -p 27017:27017 \
      -p 27018:27018 \
      -p 27883:27883 \
      -e LICENSE=accept \
      ibmcom/informix-developer-database:latest