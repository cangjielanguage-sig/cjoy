/*
 * Copyright (c) 2025 lanlingx(xiaotengfei) All rights resvered.
 * CJoy is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details.
 *
 * refer to golang src/mime/mediatype.go
 */

package cjoy.multipart

import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

struct MediaTypeTest {
    MediaTypeTest(
        let input: String,
        let mediaType: String,
        let params: HashMap<String, String>
    ) {
    }

    func doTest() {
        let obj = JoyMediaType.parse(input)
        if (obj.mediaType != mediaType) {
            @Fail("parse failed, media type is not match, input=${input}, expect=${mediaType}, real=${obj.mediaType}")
        }

        if (params != obj.params) {
            @Fail("parse failed, params is not match, input=${input}, expect=${params}, real=${obj.params}")
        }
    }
}

private func m(s: Array<String>): HashMap<String, String> {
    let sm = HashMap<String, String>()
    for (i in 0..s.size : 2) {
        sm[s[i]] = s[i + 1]
    }
    return sm
}

@Test
public class ParseMediaTypeTestCaseSuit {
    @TestCase
    public func test() {
        let nameFoo = HashMap([("name", "foo")])
        MediaTypeTest(#"form-data; name="foo""#, "form-data", nameFoo).doTest()
        MediaTypeTest(#" form-data ; name=foo"#, "form-data", nameFoo).doTest()
        MediaTypeTest(#"FORM-DATA;name="foo""#, "form-data", nameFoo).doTest()
        MediaTypeTest(#" FORM-DATA ; name="foo""#, "form-data", nameFoo).doTest()

        MediaTypeTest(#"form-data; key=value;  blah="value";name="foo" "#, "form-data",
            m("key", "value", "blah", "value", "name", "foo")).doTest()
        MediaTypeTest(#"foo; key=val1; key=the-key-appears-again-which-is-bad"#, "", m()).doTest()

        // From RFC 2231:
        MediaTypeTest(
            #"application/x-stuff; title*=us-ascii'en-us'This%20is%20%2A%2A%2Afun%2A%2A%2A"#,
            "application/x-stuff",
            m("title", "This is ***fun***")
        ).doTest()

        MediaTypeTest(
            #"message/external-body; access-type=URL; "# + #"URL*0="ftp://";"# +
                #"URL*1="cs.utk.edu/pub/moore/bulk-mailer/bulk-mailer.tar""#,
            "message/external-body",
            m("access-type", "URL", "url", "ftp://cs.utk.edu/pub/moore/bulk-mailer/bulk-mailer.tar")
        ).doTest()

        MediaTypeTest(
            #"application/x-stuff; "# + 
                #"title*0*=us-ascii'en'This%20is%20even%20more%20; "# +
                #"title*1*=%2A%2A%2Afun%2A%2A%2A%20; "# + #"title*2="isn't it!""#,
            "application/x-stuff",
            m("title", "This is even more ***fun*** isn't it!")
        ).doTest()

        // #attonly
		MediaTypeTest("attachment", "attachment", m()).doTest()
		// #attonlyucase
		MediaTypeTest("ATTACHMENT", "attachment", m()).doTest()
		// #attwithasciifilename
		MediaTypeTest(#"attachment; filename="foo.html""#,
			"attachment",
			m("filename", "foo.html")).doTest()
		// #attwithasciifilename25
		MediaTypeTest(#"attachment; filename="0000000000111111111122222""#,
			"attachment",
			m("filename", "0000000000111111111122222")).doTest()
		// #attwithasciifilename35
		MediaTypeTest(#"attachment; filename="00000000001111111111222222222233333""#,
			"attachment",
			m("filename", "00000000001111111111222222222233333")).doTest()
		// #attwithasciifnescapedchar
		MediaTypeTest(#"attachment; filename="f\oo.html""#,
			"attachment",
			m("filename", "f\\oo.html")).doTest()
		// #attwithasciifnescapedquote
		MediaTypeTest(#"attachment; filename="\"quoting\" tested.html""#,
			"attachment",
			m("filename", #""quoting" tested.html"#)).doTest()
		// #attwithquotedsemicolon
		MediaTypeTest(#"attachment; filename="Here's a semicolon;.html""#,
			"attachment",
			m("filename", "Here's a semicolon;.html")).doTest()
		// #attwithfilenameandextparam
		MediaTypeTest(#"attachment; foo="bar"; filename="foo.html""#,
			"attachment",
			m("foo", "bar", "filename", "foo.html")).doTest()
		// #attwithfilenameandextparamescaped
		MediaTypeTest(#"attachment; foo="\"\\";filename="foo.html""#,
			"attachment",
			m("foo", "\"\\", "filename", "foo.html")).doTest()
		// #attwithasciifilenameucase
		MediaTypeTest(#"attachment; FILENAME="foo.html""#,
			"attachment",
			m("filename", "foo.html")).doTest()
		// #attwithasciifilenamenq
		MediaTypeTest(#"attachment; filename=foo.html"#,
			"attachment",
			m("filename", "foo.html")).doTest()
		// #attwithasciifilenamenqs
		MediaTypeTest(#"attachment; filename=foo.html ;"#,
			"attachment",
			m("filename", "foo.html")).doTest()
		// #attwithfntokensq
		MediaTypeTest(#"attachment; filename='foo.html'"#,
			"attachment",
			m("filename", "'foo.html'")).doTest()
		// #attwithisofnplain
		MediaTypeTest(#"attachment; filename="foo-ä.html""#,
			"attachment",
			m("filename", "foo-ä.html")).doTest()
		// #attwithutf8fnplain
		MediaTypeTest(#"attachment; filename="foo-Ã¤.html""#,
			"attachment",
			m("filename", "foo-Ã¤.html")).doTest()
		// #attwithfnrawpctenca
		MediaTypeTest(#"attachment; filename="foo-%41.html""#,
			"attachment",
			m("filename", "foo-%41.html")).doTest()
		// #attwithfnusingpct
		MediaTypeTest(#"attachment; filename="50%.html""#,
			"attachment",
			m("filename", "50%.html")).doTest()
		// #attwithfnrawpctencaq
		MediaTypeTest(#"attachment; filename="foo-%\41.html""#,
			"attachment",
			m("filename", "foo-%\\41.html")).doTest()
		// #attwithnamepct
		MediaTypeTest(#"attachment; name="foo-%41.html""#,
			"attachment",
			m("name", "foo-%41.html")).doTest()
		// #attwithfilenamepctandiso
		MediaTypeTest(#"attachment; name="ä-%41.html""#,
			"attachment",
			m("name", "ä-%41.html")).doTest()
		// #attwithfnrawpctenclong
		MediaTypeTest(#"attachment; filename="foo-%c3%a4-%e2%82%ac.html""#,
			"attachment",
			m("filename", "foo-%c3%a4-%e2%82%ac.html")).doTest()
		// #attwithasciifilenamews1
		MediaTypeTest(#"attachment; filename ="foo.html""#,
			"attachment",
			m("filename", "foo.html")).doTest()
		// #attmissingdisposition
		MediaTypeTest(#"filename=foo.html"#,
			"", m()).doTest()
		// #attmissingdisposition2
		MediaTypeTest(#"x=y; filename=foo.html"#,
			"", m()).doTest()
		// #attmissingdisposition3
		MediaTypeTest(#""foo; filename=bar;baz"; filename=qux"#,
			"", m()).doTest()
		// #attmissingdisposition4
		MediaTypeTest(#"filename=foo.html, filename=bar.html"#,
			"", m()).doTest()
		// #emptydisposition
		MediaTypeTest(#"; filename=foo.html"#,
			"", m()).doTest()
		// #doublecolon
		MediaTypeTest(#": inline; attachment; filename=foo.html"#,
			"", m()).doTest()
		// #attandinline
		MediaTypeTest(#"inline; attachment; filename=foo.html"#,
			"", m()).doTest()
		// #attandinline2
		MediaTypeTest(#"attachment; inline; filename=foo.html"#,
			"", m()).doTest()
		// #attbrokenquotedfn
		MediaTypeTest(#"attachment; filename="foo.html".txt"#,
			"", m()).doTest()
		// #attbrokenquotedfn2
		MediaTypeTest(#"attachment; filename="bar"#,
			"", m()).doTest()
		// #attbrokenquotedfn3
		MediaTypeTest(#"attachment; filename=foo"bar;baz"qux"#,
			"", m()).doTest()
		// #attmultinstances
		MediaTypeTest(#"attachment; filename=foo.html, attachment; filename=bar.html"#,
			"", m()).doTest()
		// #attmissingdelim
		MediaTypeTest(#"attachment; foo=foo filename=bar"#,
			"", m()).doTest()
		// #attmissingdelim2
		MediaTypeTest(#"attachment; filename=bar foo=foo"#,
			"", m()).doTest()
		// #attmissingdelim3
		MediaTypeTest(#"attachment filename=bar"#,
			"", m()).doTest()
		// #attreversed
		MediaTypeTest(#"filename=foo.html; attachment"#,
			"", m()).doTest()
		// #attconfusedparam
		MediaTypeTest(#"attachment; xfilename=foo.html"#,
			"attachment",
			m("xfilename", "foo.html")).doTest()
		// #attcdate
		MediaTypeTest(#"attachment; creation-date="Wed, 12 Feb 1997 16:29:51 -0500""#,
			"attachment",
			m("creation-date", "Wed, 12 Feb 1997 16:29:51 -0500")).doTest()
		// #attmdate
		MediaTypeTest(#"attachment; modification-date="Wed, 12 Feb 1997 16:29:51 -0500""#,
			"attachment",
			m("modification-date", "Wed, 12 Feb 1997 16:29:51 -0500")).doTest()
		// #dispext
		MediaTypeTest(#"foobar"#, "foobar", m()).doTest()
		// #dispextbadfn
		MediaTypeTest(#"attachment; example="filename=example.txt""#,
			"attachment",
			m("example", "filename=example.txt")).doTest()
		// #attwithfn2231utf8
		MediaTypeTest(#"attachment; filename*=UTF-8''foo-%c3%a4-%e2%82%ac.html"#,
			"attachment",
			m("filename", "foo-ä-€.html")).doTest()
		// #attwithfn2231noc
		MediaTypeTest(#"attachment; filename*=''foo-%c3%a4-%e2%82%ac.html"#,
			"attachment",
			m()).doTest()
		// #attwithfn2231utf8comp
		MediaTypeTest(#"attachment; filename*=UTF-8''foo-a%cc%88.html"#,
			"attachment",
			m("filename", "foo-ä.html")).doTest()
		// #attwithfn2231ws2
		MediaTypeTest(#"attachment; filename*= UTF-8''foo-%c3%a4.html"#,
			"attachment",
			m("filename", "foo-ä.html")).doTest()
		// #attwithfn2231ws3
		MediaTypeTest(#"attachment; filename* =UTF-8''foo-%c3%a4.html"#,
			"attachment",
			m("filename", "foo-ä.html")).doTest()
		// #attwithfn2231quot
		MediaTypeTest(#"attachment; filename*="UTF-8''foo-%c3%a4.html""#,
			"attachment",
			m("filename", "foo-ä.html")).doTest()
		// #attwithfn2231quot2
		MediaTypeTest(#"attachment; filename*="foo%20bar.html""#,
			"attachment",
			m()).doTest()
		// #attwithfn2231singleqmissing
		MediaTypeTest(#"attachment; filename*=UTF-8'foo-%c3%a4.html"#,
			"attachment",
			m()).doTest()
		// #attwithfn2231nbadpct1
		MediaTypeTest(#"attachment; filename*=UTF-8''foo%"#,
			"attachment",
			m()).doTest()
		// #attwithfn2231nbadpct2
		MediaTypeTest(#"attachment; filename*=UTF-8''f%oo.html"#,
			"attachment",
			m()).doTest()
		// #attwithfn2231dpct
		MediaTypeTest(#"attachment; filename*=UTF-8''A-%2541.html"#,
			"attachment",
			m("filename", "A-%41.html")).doTest()
		// #attfncont
		MediaTypeTest(#"attachment; filename*0="foo."; filename*1="html""#,
			"attachment",
			m("filename", "foo.html")).doTest()
		// #attfncontenc
		MediaTypeTest(#"attachment; filename*0*=UTF-8''foo-%c3%a4; filename*1=".html""#,
			"attachment",
			m("filename", "foo-ä.html")).doTest()
		// #attfncontlz
		MediaTypeTest(#"attachment; filename*0="foo"; filename*01="bar""#,
			"attachment",
			m("filename", "foo")).doTest()
		// #attfncontnc
		MediaTypeTest(#"attachment; filename*0="foo"; filename*2="bar""#,
			"attachment",
			m("filename", "foo")).doTest()
		// #attfnconts1
		MediaTypeTest(#"attachment; filename*1="foo."; filename*2="html""#,
			"attachment", m()).doTest()
		// #attfncontord
		MediaTypeTest(#"attachment; filename*1="bar"; filename*0="foo""#,
			"attachment",
			m("filename", "foobar")).doTest()
		// #attfnboth
		MediaTypeTest(#"attachment; filename="foo-ae.html"; filename*=UTF-8''foo-%c3%a4.html"#,
			"attachment",
			m("filename", "foo-ä.html")).doTest()
		// #attfnboth2
		MediaTypeTest(#"attachment; filename*=UTF-8''foo-%c3%a4.html; filename="foo-ae.html""#,
			"attachment",
			m("filename", "foo-ä.html")).doTest()
		// #attfnboth3
		MediaTypeTest(#"attachment; filename*0*=ISO-8859-15''euro-sign%3d%a4; filename*=ISO-8859-1''currency-sign%3d%a4"#,
			"attachment",
			m()).doTest()
		// #attnewandfn
		MediaTypeTest(#"attachment; foobar=x; filename="foo.html""#,
			"attachment",
			m("foobar", "x", "filename", "foo.html")).doTest()

		// Browsers also just send UTF-8 directly without RFC 2231,
		// at least when the source page is served with UTF-8.
		MediaTypeTest(#"form-data; firstname="Брэд"; lastname="Фицпатрик""#,
			"form-data",
			m("firstname", "Брэд", "lastname", "Фицпатрик")).doTest()

		// Empty string used to be mishandled.
		MediaTypeTest(#"foo; bar="""#, "foo", m("bar", "")).doTest()

		// Microsoft browsers in intranet mode do not think they need to escape \ in file name.
		MediaTypeTest(#"form-data; name="file"; filename="C:\dev\go\robots.txt""#, "form-data", m("name", "file", "filename", #"C:\dev\go\robots.txt"#)).doTest()
		MediaTypeTest(#"form-data; name="file"; filename="C:\新建文件夹\中文第二次测试.mp4""#, "form-data", m("name", "file", "filename", #"C:\新建文件夹\中文第二次测试.mp4"#)).doTest()

		// issue #46323 (https://github.com/golang/go/issues/46323)
		MediaTypeTest(#"
			message/external-body; access-type=URL;
		URL*0="ftp://";
		URL*1="cs.utk.edu/pub/moore/bulk-mailer/bulk-mailer.tar";"#, // <-- trailing semicolon
			#"message/external-body"#,
			m("access-type", "URL", "url", "ftp://cs.utk.edu/pub/moore/bulk-mailer/bulk-mailer.tar")
		).doTest()

		// Issue #48866: duplicate parameters containing equal values should be allowed
		MediaTypeTest(#"text; charset=utf-8; charset=utf-8; format=fixed"#, "text", m("charset", "utf-8", "format", "fixed")).doTest()
		MediaTypeTest(#"text; charset=utf-8; format=flowed; charset=utf-8"#, "text", m("charset", "utf-8", "format", "flowed")).doTest()
    }
}
