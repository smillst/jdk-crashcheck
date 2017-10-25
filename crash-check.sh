#!/bin/sh
# Fail the whole script if any command fails
set -e

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
if [ -z "$PACKAGES" ] ; then
    PACKAGES="com java javax jdk org sun"
fi

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
# com/sun/jmx/snmp/IPAcl/Parser.java has comments that are parsed as annotations, but aren't.
JFLAGS=" -XDTA:noannotationsincomments -XDignore.symbol.file=true -Xmaxerrs 20000 -Xmaxwarns 20000\
 -source 8 -target 8 -encoding ascii -cp ${CP}"
PFLAGS="-Anocheckjdk -Aignorejdkastub -AuseDefaultsForUncheckedCode=source\
 -AprintErrorStack -Awarns -AsuppressWarnings=all "

rm -rf ${BOOTDIR} ${BINDIR} ${WORKDIR}/log
mkdir -p ${BOOTDIR} ${BINDIR} ${WORKDIR}/log
cd ${SRCDIR}

# Remove subpackages that don't compile.
DIRS=`find $PACKAGES \( -name META_INF -o -name dc\
 -o -name example -o -name jconsole -o -name pept -o -name snmp\
 \) -prune -o -type d -print`

JAVA_FILES_ARG_FILE=${WORKDIR}/log/args.txt
for d in ${DIRS} ; do
    find $d -name "*.java" -maxdepth 1 >> ${JAVA_FILES_ARG_FILE}
done
echo "Crash check"
${CF_JAVAC} -g -d ${BINDIR} ${JFLAGS} -processor ${PROCESSORS} ${PFLAGS}\
 @${JAVA_FILES_ARG_FILE} 2>&1 | tee ${WORKDIR}/log/`echo "$d" | tr / .`.log

# Check logfiles for errors and list any source files that failed to
# compile.
set +e
grep 'Compilation unit: ' ${WORKDIR}/log/*
if [ $? -ne 1 ] ; then
    exit 1
fi
set -e
