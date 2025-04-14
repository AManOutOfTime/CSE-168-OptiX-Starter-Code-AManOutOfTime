#include "SceneLoader.h"

void SceneLoader::rightMultiply(const optix::Matrix4x4& M)
{
    optix::Matrix4x4& T = transStack.top();
    T = T * M;
}

optix::float3 SceneLoader::transformPoint(optix::float3 v)
{
    optix::float4 vh = transStack.top() * optix::make_float4(v, 1);
    return optix::make_float3(vh) / vh.w; 
}

optix::float3 SceneLoader::transformNormal(optix::float3 n)
{
    return optix::make_float3(transStack.top() * make_float4(n, 0));
}

template <class T>
bool SceneLoader::readValues(std::stringstream& s, const int numvals, T* values)
{
    for (int i = 0; i < numvals; i++)
    {
        s >> values[i];
        if (s.fail())
        {
            std::cout << "Failed reading value " << i << " will skip" << std::endl;
            return false;
        }
    }
    return true;
}


std::shared_ptr<Scene> SceneLoader::load(std::string sceneFilename)
{
    // Attempt to open the scene file 
    std::ifstream in(sceneFilename);
    if (!in.is_open())
    {
        // Unable to open the file. Check if the filename is correct.
        throw std::runtime_error("Unable to open scene file " + sceneFilename);
    }

    auto scene = std::make_shared<Scene>();

    // push identity transform
    transStack.push(optix::Matrix4x4::identity());

    std::string str, cmd;

    // persistent vertex vector for parsing file
    std::vector<optix::float3> verts;
    // ambient vals
    Attributes currAttrib;
    // Read a line in the scene file in each iteration
    while (std::getline(in, str))
    {
        // Ruled out comment and blank lines
        if ((str.find_first_not_of(" \t\r\n") == std::string::npos)
            || (str[0] == '#'))
        {
            continue;
        }

        // Read a command
        std::stringstream s(str);
        s >> cmd;

        // Some arrays for storing values
        float fvalues[12];
        int ivalues[3];
        std::string svalues[1];


        if (cmd == "size" && readValues(s, 2, fvalues))
        {
            scene->width = (unsigned int)fvalues[0];
            scene->height = (unsigned int)fvalues[1];
        }
        else if (cmd == "output" && readValues(s, 1, svalues))
        {
            scene->outputFilename = svalues[0];
        }
        // TODO: use the examples above to handle other commands
        else if (cmd == "camera" && readValues(s, 10, fvalues))
        {
            scene->eye = optix::make_float3(fvalues[0], fvalues[1], fvalues[2]);
            scene->center = optix::make_float3(fvalues[3], fvalues[4], fvalues[5]);
            scene->up = optix::make_float3(fvalues[6], fvalues[7], fvalues[8]);
            scene->fovy = fvalues[9];

            /*
            // DEBUG: parsing camera values
            std::cout << "Cam Values: " << std::endl
                << "eye.x: " << scene->eye.x
                << ", eye.y: " << scene->eye.y
                << ", eye.z: " << scene->eye.z << std::endl
                << "center.x: " << scene->center.x
                << ", center.y: " << scene->center.y
                << ", center.z: " << scene->center.z << std::endl
                << "up.x: " << scene->up.x
                << ", up.y: " << scene->up.y
                << ", up.z: " << scene->up.z << std::endl;
            std::cout << "fovy: " << scene->fovy << std::endl;
            */
        }
        else if (cmd == "maxverts" && readValues(s, 1, ivalues))
        {
            //std::cout << "maxverts" << std::endl; // DEBUG
            verts.reserve(ivalues[0]); // pushback starting at 0 rather than resize
        }
        else if (cmd == "vertex" && readValues(s, 3, fvalues))
        {
            //std::cout << "vertex" << std::endl; // DEBUG
            optix::float3 tVert = optix::make_float3(fvalues[0], fvalues[1], fvalues[2]);
            verts.push_back(tVert);
        }
        else if (cmd == "tri" && readValues(s, 3, ivalues))
        {
            // std::cout << "tri" << std::endl;
            Triangle tempTri;
            tempTri.vert0 = transformPoint(verts[ivalues[0]]);
            tempTri.vert1 = transformPoint(verts[ivalues[1]]);
            tempTri.vert2 = transformPoint(verts[ivalues[2]]);
            tempTri.attrib = currAttrib;
            scene->triangles.push_back(tempTri);
        }
        else if (cmd == "sphere" && readValues(s, 4, fvalues))
        {
            optix::float3 readCenter = optix::make_float3(fvalues[0], fvalues[1], fvalues[2]);
            float readRadius = fvalues[3];

            // sphere transform
            optix::Matrix4x4 sTrans = optix::Matrix4x4::translate(readCenter) * optix::Matrix4x4::scale(optix::make_float3(readRadius));

            Sphere tempSph;
            

            // extract transforms to apply to ray for spheres
            tempSph.transform = transStack.top() * sTrans;
            tempSph.inv_transform = tempSph.transform.inverse();

            // treat as unit sphere, now that location/size is extracted
            tempSph.center = optix::make_float3(0.0f);
            tempSph.radius = 1.0f;
            tempSph.attrib = currAttrib;
            scene->spheres.push_back(tempSph);
        }
        else if (cmd == "ambient" && readValues(s, 3, fvalues))
        {
            currAttrib.ambient = optix::make_float3(fvalues[0], fvalues[1], fvalues[2]);
        }
        else if (cmd == "diffuse" && readValues(s, 3, fvalues))
        {
            currAttrib.diffuse = optix::make_float3(fvalues[0], fvalues[1], fvalues[2]);
        }
        else if (cmd == "shininess" && readValues(s, 1, fvalues))
        {
            currAttrib.shininess = fvalues[0];
        }
        else if (cmd == "emission" && readValues(s, 3, fvalues))
        {
            currAttrib.emission = optix::make_float3(fvalues[0], fvalues[1], fvalues[2]);
        }
        else if (cmd == "specular" && readValues(s, 3, fvalues))
        {
            currAttrib.specular = optix::make_float3(fvalues[0], fvalues[1], fvalues[2]);
        }
        else if (cmd == "pushTransform")
        {
            transStack.push(transStack.top());
        }
        else if (cmd == "popTransform")
        {
            transStack.pop();
        }
        else if (cmd == "translate" && readValues(s, 3, fvalues))
        {
            optix::Matrix4x4 trans = optix::Matrix4x4::translate(optix::make_float3(fvalues[0], fvalues[1], fvalues[2]));
            rightMultiply(trans);
        }
        else if (cmd == "scale" && readValues(s, 3, fvalues))
        {
            optix::Matrix4x4 scal = optix::Matrix4x4::scale(optix::make_float3(fvalues[0], fvalues[1], fvalues[2]));
            rightMultiply(scal);
        }
        else if (cmd == "rotate" && readValues(s, 4, fvalues)) // input in degrees, convert to rad
        {
            float rad = fvalues[3] * M_PIf / 180.0f;
            optix::Matrix4x4 rot = optix::Matrix4x4::rotate(rad, optix::make_float3(fvalues[0], fvalues[1], fvalues[2]));
            rightMultiply(rot);
        }
    }

    in.close();

    return scene;
}