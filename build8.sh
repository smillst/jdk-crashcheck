#!/bin/sh

# ensure CHECKERFRAMEWORK set
if [ -z "$CHECKERFRAMEWORK" ] ; then
    if [ -z "$CHECKER_FRAMEWORK" ] ; then
        export CHECKERFRAMEWORK=`(cd "$0/../.." && pwd)`
    else
        export CHECKERFRAMEWORK=${CHECKER_FRAMEWORK}
    fi
fi
[ $? -eq 0 ] || (echo "CHECKERFRAMEWORK not set; exiting" && exit 1)

# Compile all packages by default.
${PACKAGES:="com java javax jdk org sun"}
echo $PACKAGES

# TOOLSJAR and CTSYM derived from JAVA_HOME, rest from CHECKERFRAMEWORK
JSR308="`cd $CHECKERFRAMEWORK/.. && pwd`"   # base directory
WORKDIR="${CHECKERFRAMEWORK}/checker/jdk"   # working directory
AJDK="${JSR308}/annotated-jdk8u-jdk"        # annotated JDK
SRCDIR="${AJDK}/src/share/classes"
BINDIR="${WORKDIR}/build"
BOOTDIR="${WORKDIR}/bootstrap"              # initial build w/o processors
TOOLSJAR="${JAVA_HOME}/lib/tools.jar"
LT_BIN="${JSR308}/jsr308-langtools/build/classes"
LT_JAVAC="${JSR308}/jsr308-langtools/dist/bin/javac"
CF_BIN="${CHECKERFRAMEWORK}/checker/build"
CF_DIST="${CHECKERFRAMEWORK}/checker/dist"
CF_JAR="${CF_DIST}/checker.jar"
CF_JAVAC="java -Xmx512m -jar ${CF_JAR} -Xbootclasspath/p:${BOOTDIR}"
CP="${BINDIR}:${BOOTDIR}:${LT_BIN}:${TOOLSJAR}:${CF_BIN}:${CF_JAR}"
JFLAGS="-XDignore.symbol.file=true -Xmaxerrs 20000 -Xmaxwarns 20000\
 -source 8 -target 8 -encoding ascii -cp ${CP}"
#PROCESSORS="org.checkerframework.common.value.ValueChecker"
#PROCESSORS="nullness"
PFLAGS="-Anocheckjdk -Aignorejdkastub -AuseDefaultsForUncheckedCode=source\
 -AprintErrorStack -Awarns -Afilenames  -AsuppressWarnings=all "

##Not working on Travis for some reason
#set -o pipefail

rm -rf ${BOOTDIR} ${BINDIR} ${WORKDIR}/log
mkdir -p ${BOOTDIR} ${BINDIR} ${WORKDIR}/log
cd ${SRCDIR}

DIRS=`find $PACKAGES \( -name META_INF -o -name dc\
 -o -name example -o -name jconsole -o -name pept -o -name snmp\
 \) -prune -o -type d -print`

# Build the remaining packages one at a time because building all of
# them together makes the compiler run out of memory.
JAVA_FILES_ARG_FILE=${WORKDIR}/log/args.txt
for d in ${DIRS} ; do
    find $d -name "*.java" >> ${JAVA_FILES_ARG_FILE}
done
echo "Crash check"
${CF_JAVAC} -g -d ${BINDIR} ${JFLAGS} -processor ${PROCESSORS} ${PFLAGS}\
 @${JAVA_FILES_ARG_FILE} 2>&1 | tee ${WORKDIR}/log/`echo "$d" | tr / .`.log

# Check logfiles for errors and list any source files that failed to
# compile.
grep 'Compilation unit: ' ${WORKDIR}/log/*
if [ $? -ne 1 ] ; then
    exit 1
fi
