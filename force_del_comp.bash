#! /bin/bash
#
# Copyright (c) 2018 Actian Corporation
#
# This script deletes the rows for an application component from the repository tables.
# It is a kind of "last resort cleanup action" if the component in the repository got corrupted,
# so it could not be deleted from the Workbench or using the command:
#   w4gldev destroyapp database application -ccomponent
#

if [ $# -lt 3 ]
then
    printf "USAGE:\n\t$0 <database> <application> <component>\n\n"
    exit 1
fi

export DBNAME=$1
export APPNAME=$2
export COMPNAME=$3

if [ -z "$DBNAME" ]
then
    printf "Empty <database> supplied!\n\n"
    exit 2
fi
if [ -z "$APPNAME" ]
then
    printf "Empty <application> supplied!\n\n"
    exit 2
fi
if [ -z "$COMPNAME" ]
then
    printf "Empty <component> supplied!\n\n"
    exit 2
fi

tm -qSQL -S ${DBNAME} <<EOF
DECLARE GLOBAL TEMPORARY TABLE ents AS
SELECT c.entity_id FROM ii_entities c, ii_entities a
WHERE lowercase(c.entity_name) = lowercase('${COMPNAME}')
AND lowercase(a.entity_name)= lowercase('${APPNAME}')
AND a.entity_id = c.folder_id
ON COMMIT PRESERVE ROWS WITH NORECOVERY;
COMMIT;
delete from ii_entities where entity_id IN(SELECT entity_id FROM session.ents);
delete from ii_components where entity_id IN(SELECT entity_id FROM session.ents);
delete from ii_srcobj_encoded where entity_id IN(SELECT entity_id FROM session.ents);
delete from ii_locks where entity_id IN(SELECT entity_id FROM session.ents);
delete from ii_app_cntns_comp where comp_id IN(SELECT entity_id FROM session.ents);
update ii_components set current_make=0 where entity_id in(
 SELECT src_entity_id from ii_dependencies where dest_entity_id IN(
   SELECT entity_id FROM session.ents) AND rel_class_type='DEPENDS_ON');
delete from ii_dependencies where src_entity_id IN(SELECT entity_id FROM session.ents)
 or dest_entity_id IN(SELECT entity_id FROM session.ents) ;
commit;\g\q
EOF

exit $?
