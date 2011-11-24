# macros.py

# Subversion Details
# $LastChangedDate: 2006-08-14 00:53:30 +0200 (Mon, 14 Aug 2006) $
# $LastChangedBy: fuzzyman $
# $HeadURL: https://svn.rest2web.python-hosting.com/trunk/macros.py $
# $LastChangedRevision: 202 $

# User macros for rest2web 
# http://www.voidspace.org.uk/python/rest2web

# Copyright Michael Foord 2006.
# Released subject to the BSD License
# Please see http://www.voidspace.org.uk/python/license.shtml

# For information about bugfixes, updates and support, please join the
# rest2web mailing list.
# http://lists.sourceforge.net/lists/listinfo/rest2web-develop
# Comments, suggestions and bug reports welcome.
# Scripts maintained at http://www.voidspace.org.uk/python/index.shtml
# E-mail fuzzyman@voidspace.org.uk


uservalues = {}
namespace = {}

def set_uservalues(n, u):
    """
    Set the namespace and uservalues for the page.
    
    This means that macros can use 'uservalues' and 'namespace'.
    """
    global namespace
    global uservalues
    uservalues = u
    namespace = n

# add to this dictionary to add extra acronyms
# keys should be lowercase
acronyms = {
    'usb': 'Universal Serial Bus', 
    'YAGNI': 'You Aint Gonna Need It',
    
}
